# Tracker Pessoal de Desempenho Diário — Spec de Arquitetura

> Documento final do mapa de wayfinder "Personal Performance Tracker — Architecture Spec". Cada decisão aqui compila o que foi fechado nos 12 tickets do mapa — o detalhe e a justificativa completa de cada uma estão em `.scratch/personal-performance-tracker/issues/`. Este documento é a materialização do destino, não uma nova rodada de decisões.

---

## 1. Visão geral da arquitetura

### 1.1 Camadas

```mermaid
graph TB
    subgraph Frontend["Flutter (Web + Desktop)"]
        UI[Presentation: Widgets + Blocs]
        FData[Data: Repositories + Datasources]
        FDomain[Domain: Entities + UseCases]
        UI --> FDomain
        FDomain --> FData
    end

    subgraph Backend["NestJS"]
        Presentation[Presentation: Controllers + Guards]
        Application[Application: UseCases + DTOs]
        Domain[Domain: Entities, VOs, Domain Services]
        Infra[Infrastructure: TypeORM Repositories, Firebase Admin, sharp, FFmpeg]
        Presentation --> Application
        Application --> Domain
        Application --> Infra
        Infra --> Domain
    end

    DB[(Postgres)]
    Firebase[(Firebase Auth)]
    Volume[/Docker volume: fotos + vídeos/]

    FData -- HTTPS + Bearer token --> Presentation
    Presentation -- valida ID token --> Firebase
    Infra --> DB
    Infra --> Volume
```

**Regra de dependência**: `Domain` não conhece `Infrastructure` nem `Presentation` em nenhum dos dois lados. `Application` orquestra casos de uso chamando `Domain` (regras de negócio puras) e `Infrastructure` (I/O), nunca o contrário.

### 1.2 Fluxo ponta a ponta: "arrastei o slider"

```mermaid
sequenceDiagram
    participant U as Usuário
    participant W as Slider Widget (Flutter)
    participant B as OccurrenceBloc
    participant R as OccurrenceRepository (Flutter)
    participant API as PUT /occurrences/:taskId/:date
    participant UC as UpsertOccurrenceUseCase
    participant Calc as PerformanceCalculationService
    participant DB as Postgres

    U->>W: arrasta o slider (10 em 10%)
    W->>B: onChanged(value) — a cada tick do drag
    B->>B: debounce (ex. 400ms sem novo tick)
    B->>W: estado "salvando..."
    B->>R: upsert(taskId, date, percentage)
    R->>API: PUT idempotente (userId + taskId + date)
    API->>UC: execute({ userId, taskId, date, percentage })
    UC->>DB: upsert TaskOccurrence (via UserScopedRepository)
    UC->>Calc: recompute day performance
    Calc-->>UC: dayPerformance %
    UC-->>API: { occurrence, dayPerformance }
    API-->>R: 200 OK
    R-->>B: sucesso
    B->>W: estado "salvo" + atualiza cor da célula do dia
    Note over B,R: Se a rede falhar, o valor arrastado não se perde:<br/>B mantém o valor local e mostra "erro, tentando de novo"
```

Pontos de design deliberados nesse fluxo:
- **Debounce no cliente**, não no servidor — o servidor sempre recebe um valor final por parada de arraste, nunca uma rajada por tick.
- **Idempotência pela chave natural** (`userId + taskId + date`), não por id sintético — a ocorrência é virtual até esse upsert, então não existe id prévio para referenciar.
- **Sem refetch do mês**: a resposta do upsert já traz o suficiente para atualizar a UI local (ver [Calendar read contract](issues/03-calendar-read-contract.md)).
- **Erro não descarta o valor arrastado**: o Bloc mantém o valor otimista localmente e re-tenta, nunca reverte silenciosamente para o que veio do servidor antes do erro.

---

## 2. Modelo de domínio

### 2.1 Agregados e entidades

- **`Task`** (aggregate root): `id`, `userId`, `name`, `type: 'REGULAR' | 'WEIGHT'`, `weight: number` (0.5–2, padrão 1), `restPolicy?: RestPolicy`, `recurrenceHistory: RecurrenceRule[]` (versionado — ver §2.3), `startsOn`, `endsOn?`.
- **`TaskOccurrence`** (entidade, não agregado próprio — vive sob a chave natural de `Task`): `userId`, `taskId`, `date: LocalDate`, `state: { type: 'PERCENTAGE'; value: number } | { type: 'REST' }`, `photoPath?`, `weightKg?` (só quando `Task.type === 'WEIGHT'`), `origin: 'RECURRENCE' | 'DERIVED'`. **Só existe linha quando algo foi registrado** — nunca pré-materializada.

### 2.2 Value Objects

- **`LocalDate`**: branded string ISO (`YYYY-MM-DD`), não classe. Comparável com `<`/`>`/`===` nativos. Ver [RecurrenceRule VO validation](issues/09-recurrence-rule-vo-validation.md).
- **`RecurrenceRule`**: VO puro, método único `occursOn(date): boolean`. `pattern` é uma union: `DAILY | WEEKLY_DAYS | MONTHLY_DAY | INTERVAL | PAUSED`. Nunca toca fuso horário real.
- **`RestPolicy`**: `{ count: number; per: 'WEEK' | 'MONTH' }`. Pertence à `Task`, não à recorrência — recorrência responde "quando é esperado", `RestPolicy` responde "quantas dispensas são legítimas".

```typescript
type Weekday = 'SUN' | 'MON' | 'TUE' | 'WED' | 'THU' | 'FRI' | 'SAT';
type LocalDate = string & { __brand: 'LocalDate' };

type RecurrencePattern =
  | { type: 'DAILY' }
  | { type: 'WEEKLY_DAYS'; days: Weekday[] }
  | { type: 'MONTHLY_DAY'; day: number | 'LAST' }
  | { type: 'INTERVAL'; everyNDays: number }
  | { type: 'PAUSED' }; // occursOn sempre false

class RecurrenceRule {
  readonly v: 1 = 1;
  constructor(
    readonly pattern: RecurrencePattern,
    readonly startsOn: LocalDate,
    readonly endsOn?: LocalDate,
  ) {}

  occursOn(date: LocalDate): boolean {
    if (date < this.startsOn) return false;
    if (this.endsOn && date > this.endsOn) return false;
    switch (this.pattern.type) {
      case 'DAILY': return true;
      case 'PAUSED': return false;
      case 'WEEKLY_DAYS': return this.pattern.days.includes(dayOfWeek(date));
      case 'MONTHLY_DAY': return this.matchesMonthlyDay(date);
      case 'INTERVAL': return daysBetween(this.startsOn, date) % this.pattern.everyNDays === 0;
    }
  }

  private matchesMonthlyDay(date: LocalDate): boolean {
    const { day } = this.pattern as { type: 'MONTHLY_DAY'; day: number | 'LAST' };
    return day === 'LAST' ? date === lastDayOfMonth(date) : dayOfMonth(date) === day;
  }
}
```

### 2.3 `TaskRecurrenceHistory` — versionamento da regra

Em vez de `Task` guardar uma `RecurrenceRule` mutável, guarda uma **lista ordenada e não sobreposta de versões**, cada uma usando os próprios `startsOn`/`endsOn` do VO como janela de vigência. Editar a recorrência fecha a versão atual e abre uma nova — nunca sobrescreve. Isso resolve, na raiz, o problema de "editar muda o passado" (ver [Monthly snapshot for historical immutability](issues/05-monthly-snapshot-immutability.md)), inclusive dentro do mês corrente ainda aberto — coisa que um snapshot mensal nunca cobriria.

```typescript
class TaskRecurrenceHistory {
  constructor(private readonly versions: RecurrenceRule[]) {} // ordenadas por startsOn, sem sobreposição

  occursOn(date: LocalDate): boolean {
    const version = this.versions.find(v => v.startsOn <= date && (!v.endsOn || date <= v.endsOn));
    return version?.occursOn(date) ?? false;
  }
}
```

Pausas (viagem, lesão) são apenas mais uma versão, com `pattern: { type: 'PAUSED' }` — nenhuma entidade nova.

**Gap aceito e documentado**: a mesma retroatividade vale, em teoria, para `restPolicy` e `weight` (também entram no cálculo de desempenho), mas o versionamento foi escopado deliberadamente só para `RecurrenceRule` — ver [Monthly snapshot for historical immutability](issues/05-monthly-snapshot-immutability.md).

### 2.4 Regra de domínio: `RestQuotaPolicy`

Serviço de domínio stateless e separado — não é método de `Task` nem lógica embutida no serviço de cálculo — porque precisa da lista de folgas do período, não só da data isolada (ver [Weekly quota placement](issues/04-weekly-quota-placement.md)):

```typescript
class RestQuotaPolicy {
  evaluate(
    policy: RestPolicy | undefined,
    restDaysInPeriodUpToDate: LocalDate[], // ordenadas, incluindo a data atual
    date: LocalDate,
  ): 'WITHIN_QUOTA' | 'OVER_QUOTA' {
    if (!policy) return 'WITHIN_QUOTA';
    const ordinal = restDaysInPeriodUpToDate.indexOf(date) + 1;
    return ordinal <= policy.count ? 'WITHIN_QUOTA' : 'OVER_QUOTA';
  }
}
```

Agrupamento de semana-domingo é uma função pura em memória (`startOfWeekSunday(date)`), nunca SQL — nada de `date_trunc` (base segunda-feira, errado pra esse domínio).

### 2.5 Regra de domínio: `PerformanceCalculationService`

O serviço isolado e trocável pedido no brief. Orquestra, para um dia:
1. Para cada tarefa cujo `TaskRecurrenceHistory.occursOn(date)` seja `true` **e** `origin !== 'DERIVED'` → entra no denominador.
2. Se a ocorrência não existe → `UNFILLED` (excluído, não é 0%).
3. Se existe e é `PERCENTAGE` → usa o valor direto.
4. Se existe e é `REST` → delega a `RestQuotaPolicy`: `WITHIN_QUOTA` = 100%, `OVER_QUOTA` = 0%.
5. Média ponderada por `task.weight` sobre os itens do passo 1 que não são `UNFILLED`.

```typescript
interface DayPerformanceInput {
  task: Task;
  occurrence?: TaskOccurrence; // undefined = unfilled
  restDaysInWeekOrMonthUpToDate: LocalDate[];
}

class PerformanceCalculationService {
  calculateDay(date: LocalDate, inputs: DayPerformanceInput[]): number | null {
    const expected = inputs.filter(i => i.task.recurrenceHistory.occursOn(date) && i.occurrence?.origin !== 'DERIVED');
    const scored = expected
      .map(i => this.scoreOne(i, date))
      .filter((s): s is { weight: number; value: number } => s !== null); // null = UNFILLED, excluído

    if (scored.length === 0) return null; // nenhuma tarefa esperada pontuável neste dia
    const totalWeight = scored.reduce((sum, s) => sum + s.weight, 0);
    return scored.reduce((sum, s) => sum + s.value * s.weight, 0) / totalWeight;
  }

  private scoreOne(input: DayPerformanceInput, date: LocalDate): { weight: number; value: number } | null {
    if (!input.occurrence) return null; // UNFILLED
    const { occurrence, task } = input;
    if (occurrence.state.type === 'PERCENTAGE') return { weight: task.weight, value: occurrence.state.value };
    const quota = new RestQuotaPolicy().evaluate(task.restPolicy, input.restDaysInWeekOrMonthUpToDate, date);
    return { weight: task.weight, value: quota === 'WITHIN_QUOTA' ? 100 : 0 };
  }
}
```

### 2.6 Domínio vs. caso de uso — o que é o quê

| Regra | Onde mora | Por quê |
|---|---|---|
| `occursOn` de uma versão de recorrência | `RecurrenceRule` (domínio, VO) | Pura, sem I/O, invariante da própria regra |
| Selecionar a versão vigente numa data | `TaskRecurrenceHistory` (domínio) | Pura, invariante de não-sobreposição |
| Avaliar se uma folga está dentro da cota | `RestQuotaPolicy` (domínio, serviço) | Pura dado o input, mas precisa de coleção — não cabe no VO |
| Calcular desempenho do dia/mês | `PerformanceCalculationService` (domínio, serviço) | A regra de negócio central, isolada e trocável, sem I/O |
| Buscar ocorrências do mês, mesclar com dias esperados, persistir upsert | `UpsertOccurrenceUseCase` / `GetCalendarMonthUseCase` (aplicação) | Orquestração com I/O — não é regra, é fluxo |
| Redimensionar/converter foto | `PhotoProcessingService` chamado pelo use case (infraestrutura + aplicação) | I/O e biblioteca externa (sharp), não regra de domínio |

---

## 3. Modelo de dados

### 3.1 Tabelas

```sql
-- users: projeção mínima da identidade do Firebase, chaveada por uid
CREATE TABLE users (
  id            TEXT PRIMARY KEY,        -- Firebase uid
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE tasks (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        TEXT NOT NULL REFERENCES users(id),
  name           TEXT NOT NULL,
  type           TEXT NOT NULL CHECK (type IN ('REGULAR', 'WEIGHT')),
  weight         NUMERIC(3,1) NOT NULL DEFAULT 1 CHECK (weight BETWEEN 0.5 AND 2),
  rest_policy    JSONB,                  -- { count: number; per: 'WEEK' | 'MONTH' } | null
  starts_on      DATE NOT NULL,
  ends_on        DATE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tasks_user ON tasks(user_id);

-- versões da RecurrenceRule — ver TaskRecurrenceHistory (§2.3)
CREATE TABLE task_recurrence_versions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id      UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  v            SMALLINT NOT NULL DEFAULT 1,
  pattern      JSONB NOT NULL,          -- RecurrencePattern, validado na fronteira (zod/class-validator)
  starts_on    DATE NOT NULL,
  ends_on      DATE,
  CONSTRAINT no_overlap EXCLUDE USING gist (
    task_id WITH =,
    daterange(starts_on, COALESCE(ends_on, 'infinity'::date), '[]') WITH &&
  )
);
CREATE INDEX idx_recurrence_versions_task ON task_recurrence_versions(task_id, starts_on);

CREATE TABLE task_occurrences (
  user_id      TEXT NOT NULL REFERENCES users(id),
  task_id      UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  date         DATE NOT NULL,           -- plain DATE, nunca TIMESTAMPTZ — ver Timezone and persisted date
  state_type   TEXT NOT NULL CHECK (state_type IN ('PERCENTAGE', 'REST')),
  percentage   SMALLINT CHECK (percentage BETWEEN 0 AND 100 AND percentage % 10 = 0),
  origin       TEXT NOT NULL DEFAULT 'RECURRENCE' CHECK (origin IN ('RECURRENCE', 'DERIVED')),
  photo_path   TEXT,
  weight_kg    NUMERIC(5,2),            -- só populado quando tasks.type = 'WEIGHT'
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, task_id, date)  -- chave natural, não id sintético — casa com o upsert idempotente
);
CREATE INDEX idx_occurrences_user_date ON task_occurrences(user_id, date);
CREATE INDEX idx_occurrences_weight_series ON task_occurrences(user_id, task_id, date) WHERE weight_kg IS NOT NULL;
```

Sem `date_trunc`/`generate_series` em lugar nenhum — toda expansão de recorrência e agrupamento semanal acontece em memória na aplicação (ver [Virtual read performance](issues/02-virtual-read-performance.md) e [Weekly quota placement](issues/04-weekly-quota-placement.md)).

### 3.2 Primeira migration (TypeORM)

```typescript
export class InitialSchema1700000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS pgcrypto`); // gen_random_uuid()
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS btree_gist`); // EXCLUDE USING gist com =

    await queryRunner.query(`
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    `);

    await queryRunner.query(`
      CREATE TABLE tasks (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id TEXT NOT NULL REFERENCES users(id),
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('REGULAR', 'WEIGHT')),
        weight NUMERIC(3,1) NOT NULL DEFAULT 1 CHECK (weight BETWEEN 0.5 AND 2),
        rest_policy JSONB,
        starts_on DATE NOT NULL,
        ends_on DATE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
      CREATE INDEX idx_tasks_user ON tasks(user_id);
    `);

    await queryRunner.query(`
      CREATE TABLE task_recurrence_versions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        v SMALLINT NOT NULL DEFAULT 1,
        pattern JSONB NOT NULL,
        starts_on DATE NOT NULL,
        ends_on DATE,
        CONSTRAINT no_overlap EXCLUDE USING gist (
          task_id WITH =,
          daterange(starts_on, COALESCE(ends_on, 'infinity'::date), '[]') WITH &&
        )
      );
      CREATE INDEX idx_recurrence_versions_task ON task_recurrence_versions(task_id, starts_on);
    `);

    await queryRunner.query(`
      CREATE TABLE task_occurrences (
        user_id TEXT NOT NULL REFERENCES users(id),
        task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        date DATE NOT NULL,
        state_type TEXT NOT NULL CHECK (state_type IN ('PERCENTAGE', 'REST')),
        percentage SMALLINT CHECK (percentage BETWEEN 0 AND 100 AND percentage % 10 = 0),
        origin TEXT NOT NULL DEFAULT 'RECURRENCE' CHECK (origin IN ('RECURRENCE', 'DERIVED')),
        photo_path TEXT,
        weight_kg NUMERIC(5,2),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        PRIMARY KEY (user_id, task_id, date)
      );
      CREATE INDEX idx_occurrences_user_date ON task_occurrences(user_id, date);
      CREATE INDEX idx_occurrences_weight_series ON task_occurrences(user_id, task_id, date)
        WHERE weight_kg IS NOT NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE task_occurrences`);
    await queryRunner.query(`DROP TABLE task_recurrence_versions`);
    await queryRunner.query(`DROP TABLE tasks`);
    await queryRunner.query(`DROP TABLE users`);
  }
}
```

`synchronize: false` sempre — migrations versionadas, rodadas no boot da API (ver §7).

---

## 4. Contrato REST

Todos os endpoints exigem `Authorization: Bearer <Firebase ID token>`, validado pelo `FirebaseAuthGuard`.

| Método | Path | Descrição |
|---|---|---|
| `GET` | `/tasks` | Lista as tarefas ativas do usuário. Cacheável no cliente — raramente muda. |
| `POST` | `/tasks` | Cria uma tarefa (nome, tipo, weight, restPolicy, recorrência inicial). |
| `PATCH` | `/tasks/:taskId/recurrence` | Fecha a versão de recorrência atual e abre uma nova a partir de hoje (ver §2.3). |
| `POST` | `/tasks/:taskId/pause` / `/resume` | Insere/fecha uma versão `PAUSED`. |
| `GET` | `/calendar/:year/:month` | `{ serverToday: LocalDate, days: DayDto[] }` — dias do mês (padded pra semanas completas), com desempenho agregado e ocorrências registradas. |
| `PUT` | `/occurrences/:taskId/:date` | Upsert idempotente. Body: `{ state: { type: 'PERCENTAGE', value } \| { type: 'REST' }, weightKg? }`. Retorna `{ occurrence, dayPerformance }`. |
| `POST` | `/occurrences/:taskId/:date/photo` | Upload multipart; processa síncrono (sharp) e retorna o path servível. |
| `GET` | `/occurrences/:taskId/:date/photo` | Serve o WebP processado, autenticado + escopado por usuário. |
| `GET` | `/reports/monthly/:year/:month` | Desempenho mensal geral e por tarefa, `isComplete`, contagem de folgas (usadas/restantes por cota). |
| `GET` | `/reports/annual/:year` | 12 meses, cada um com `{ performance: number \| null, isComplete: boolean }` — meses correntes/futuros vêm `isComplete: false` e sem cor no frontend. |
| `GET` | `/reports/weight-series` | Série temporal `{ date, weightKg }[]`, independente do calendário (filtro simples sobre `task_occurrences`). |
| `GET` | `/reports/weight-summary/:year/:month` | `{ opening: number \| null, closing: number \| null }` — cascateando pra trás em busca da leitura mais recente se o mês adjacente estiver vazio (ver [Weight aggregate design](issues/07-weight-aggregate-design.md)). |
| `GET` | `/timelapse/status` | `{ status: 'READY' \| 'GENERATING' \| 'FAILED' \| 'NOT_YET_GENERATED', generatedAt?, videoUrl? }`. |

**Erros**: `401` (token ausente/inválido), `404` (recurso não encontrado **ou** pertence a outro usuário — nunca `403`, pra não vazar existência), `409` (violação de invariante, ex. sobreposição de versão de recorrência), `422` (payload inválido, ex. percentual fora de múltiplos de 10).

---

## 5. Estrutura de pastas do monorepo

```
task-tracker/
├── backend/
│   ├── src/
│   │   ├── domain/                    # VOs, entidades, serviços de domínio — zero I/O
│   │   │   ├── task/
│   │   │   │   ├── task.entity.ts
│   │   │   │   ├── recurrence-rule.vo.ts
│   │   │   │   ├── task-recurrence-history.ts
│   │   │   │   └── rest-policy.vo.ts
│   │   │   ├── occurrence/
│   │   │   │   └── task-occurrence.entity.ts
│   │   │   └── performance/
│   │   │       ├── performance-calculation.service.ts
│   │   │       └── rest-quota-policy.service.ts
│   │   ├── application/               # casos de uso, DTOs, portas (interfaces)
│   │   │   ├── task/
│   │   │   ├── occurrence/
│   │   │   │   └── upsert-occurrence.use-case.ts
│   │   │   ├── calendar/
│   │   │   │   └── get-calendar-month.use-case.ts
│   │   │   ├── reports/
│   │   │   └── ports/
│   │   │       └── clock.port.ts
│   │   ├── infrastructure/            # TypeORM, Firebase Admin, sharp, FFmpeg, adapters
│   │   │   ├── persistence/
│   │   │   │   ├── typeorm/
│   │   │   │   │   ├── migrations/
│   │   │   │   │   ├── task.repository.ts
│   │   │   │   │   └── user-scoped.repository.ts
│   │   │   │   └── mappers/           # JSONB <-> VO
│   │   │   ├── auth/
│   │   │   │   └── firebase-auth.guard.ts
│   │   │   ├── photo/
│   │   │   │   └── photo-processing.service.ts
│   │   │   ├── video/
│   │   │   │   └── timelapse.job.ts
│   │   │   └── clock/
│   │   │       └── sao-paulo-clock.adapter.ts
│   │   └── presentation/              # controllers, decorators, DTOs de request/response
│   │       ├── task.controller.ts
│   │       ├── calendar.controller.ts
│   │       ├── occurrence.controller.ts
│   │       └── reports.controller.ts
│   ├── test/
│   │   ├── unit/                      # domínio + aplicação, sem banco
│   │   └── integration/               # repositórios + endpoints, banco real
│   ├── Dockerfile
│   └── package.json
├── frontend/
│   ├── lib/
│   │   ├── modules/
│   │   │   ├── calendar/
│   │   │   │   ├── domain/            # entities, usecases (interfaces + puro Dart)
│   │   │   │   ├── data/              # repositories (impl), datasources (http)
│   │   │   │   └── presentation/      # pages, widgets, blocs
│   │   │   ├── reports/
│   │   │   ├── task/
│   │   │   └── auth/
│   │   ├── shared/                    # design tokens, cores, widgets comuns
│   │   └── app_module.dart            # flutter_modular root
│   ├── test/
│   └── pubspec.yaml
├── docker-compose.yml
├── docker-compose.portainer.yml
├── .github/workflows/ci.yml
└── README.md
```

---

## 6. Módulos Flutter (flutter_modular)

Cada módulo replica `domain / data / presentation`, espelhando o backend:

```dart
class CalendarModule extends Module {
  @override
  void binds(i) {
    i.addLazySingleton<CalendarRepository>(CalendarRepositoryImpl.new);
    i.addLazySingleton(GetCalendarMonthUseCase.new);
    i.addLazySingleton(UpsertOccurrenceUseCase.new);
    i.addLazySingleton(() => OccurrenceBloc(i.get(), i.get()));
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const CalendarPage());
  }
}
```

- **Domain** (`modules/calendar/domain/`): entidades puras Dart (`DayPerformance`, `TaskOccurrence`), casos de uso como classes com `call()`, interfaces de repositório (`abstract class CalendarRepository`) — sem `http`/`dio` importado aqui.
- **Data** (`modules/calendar/data/`): `CalendarRepositoryImpl` implementa a interface, injeta um `CalendarDatasource` (que fala `http`), mapeia DTOs JSON para entidades de domínio.
- **Presentation** (`modules/calendar/presentation/`): `CalendarPage` (o `table_calendar` com `startingDayOfWeek: StartingDayOfWeek.sunday`), `OccurrenceBloc` (estados: `initial`, `loaded`, `saving`, `saved`, `error(lastKnownValue)` — o erro nunca descarta o valor arrastado), widgets de slider por tarefa.
- **`AnnualCalendarWidget`** (módulo `reports`): grade própria de 12 meses, consumindo `GET /reports/annual/:year`, aplicando a escala de cores no cliente (backend só devolve percentuais + `isComplete`).

---

## 7. Infraestrutura

### 7.1 Dockerfile multi-stage (backend)

```dockerfile
# build
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# runtime
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY --from=build /app/migrations ./migrations
CMD ["sh", "-c", "npm run migration:run && node dist/main.js"]
```

Migrations rodam no boot, antes do processo da API subir — falha de migration falha o container inteiro (fail-fast, não sobe API com schema desatualizado).

### 7.2 `docker-compose.yml` (dev)

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: tracker
      POSTGRES_USER: tracker
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U tracker"]
      interval: 5s
      timeout: 5s
      retries: 5

  api:
    build: ./backend
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DATABASE_URL: postgres://tracker:${DB_PASSWORD}@postgres:5432/tracker
      FIREBASE_PROJECT_ID: ${FIREBASE_PROJECT_ID}
      APP_TIMEZONE: America/Sao_Paulo
    volumes:
      - photos_data:/data/photos
      - videos_data:/data/videos
    ports:
      - "3000:3000"

volumes:
  postgres_data:
  photos_data:
  videos_data:
```

### 7.3 Stack Portainer (produção)

Mesma composição, sem bind mounts de código-fonte, com `restart: unless-stopped`, segredos via Portainer secrets em vez de `.env` versionado, e um serviço adicional de backup (`pg_dump` agendado, escrevendo num volume separado montado só nesse serviço).

### 7.4 Variáveis de ambiente

| Variável | Uso |
|---|---|
| `DATABASE_URL` | Conexão TypeORM |
| `FIREBASE_PROJECT_ID` / credenciais do Admin SDK | Validação do ID token |
| `APP_TIMEZONE` | Constante, não configurável de fato — documenta a decisão fixa (America/Sao_Paulo) |
| `PHOTOS_VOLUME_PATH` / `VIDEOS_VOLUME_PATH` | Paths dos volumes locais |

---

## 8. Segurança

Camadas, do request até o banco (ver [User isolation strategy](issues/01-user-isolation-strategy.md) para a decisão completa e a justificativa de **não** usar RLS):

```typescript
// 1. Guard — valida o ID token, nunca confia em nada do client além dele
@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = request.headers.authorization?.replace('Bearer ', '');
    const decoded = await this.firebaseAdmin.auth().verifyIdToken(token);
    request.user = { uid: decoded.uid };
    return true;
  }
}

// 2. Propagação explícita — nunca ambiente/AsyncLocalStorage
@Get(':taskId')
getTask(@CurrentUserId() userId: string, @Param('taskId') taskId: string) {
  return this.getTaskUseCase.execute({ userId, taskId });
}

// 3. Base repository — impossível montar query sem escopo
abstract class UserScopedRepository<T extends { userId: string }> {
  protected constructor(protected readonly repo: Repository<T>) {}
  protected scoped(userId: string): SelectQueryBuilder<T> {
    return this.repo.createQueryBuilder('e').where('e.userId = :userId', { userId });
  }
  findOneForUser(userId: string, id: string): Promise<T | null> {
    return this.scoped(userId).andWhere('e.id = :id', { id }).getOne();
  }
}

// 4. Rede de segurança automatizada — um teste de contrato, rodado contra todo repositório
function itIsolatesByUser<T>(repo: UserScopedRepository<T>, seed: (userId: string) => Promise<T>) {
  it('never returns another user data', async () => {
    const owned = await seed('user-a');
    expect(await repo.findOneForUser('user-b', owned.id)).toBeNull(); // 404, não 403
  });
}
```

Fotos servidas pelo mesmo guard + mesmo escopo (`GET /occurrences/:taskId/:date/photo`), sem URL assinada separada — um único modelo de isolamento pra tudo.

---

## 9. Estratégia de testes

| Camada | Tipo | O quê |
|---|---|---|
| Domínio (`RecurrenceRule`, `PerformanceCalculationService`, `RestQuotaPolicy`) | Unitário, sem banco | Regras de negócio puras — a maior parte da cobertura vive aqui |
| Aplicação (casos de uso) | Unitário, repositórios fake/in-memory | Orquestração, sem I/O real |
| Infraestrutura (repositórios, `UserScopedRepository`) | Integração, banco real | Isolamento por usuário, constraints, migrations |
| Presentation (controllers) | Integração (supertest) | Guards, validação, códigos de erro |

### 9.1 Teste do `PerformanceCalculationService` (folga + dia não preenchido)

```typescript
describe('PerformanceCalculationService', () => {
  const service = new PerformanceCalculationService();
  const gym = taskFixture({ weight: 1, restPolicy: { count: 2, per: 'WEEK' } });
  const diet = taskFixture({ weight: 1 });

  it('excludes an unfilled expected task from the average, not as 0%', () => {
    const result = service.calculateDay(date('2026-03-10'), [
      { task: gym, occurrence: undefined, restDaysInWeekOrMonthUpToDate: [] }, // unfilled
      { task: diet, occurrence: occurrenceFixture({ state: { type: 'PERCENTAGE', value: 80 } }), restDaysInWeekOrMonthUpToDate: [] },
    ]);
    expect(result).toBe(80); // só a diet entra — gym unfilled não vira 0
  });

  it('scores a rest day within quota as 100%', () => {
    const restDays = [date('2026-03-08'), date('2026-03-10')]; // 2ª folga da semana
    const result = service.calculateDay(date('2026-03-10'), [
      { task: gym, occurrence: occurrenceFixture({ state: { type: 'REST' } }), restDaysInWeekOrMonthUpToDate: restDays },
    ]);
    expect(result).toBe(100);
  });

  it('scores a rest day over quota as 0%', () => {
    const restDays = [date('2026-03-01'), date('2026-03-08'), date('2026-03-10')]; // 3ª folga da semana
    const result = service.calculateDay(date('2026-03-10'), [
      { task: gym, occurrence: occurrenceFixture({ state: { type: 'REST' } }), restDaysInWeekOrMonthUpToDate: restDays },
    ]);
    expect(result).toBe(0);
  });

  it('returns null when no task is expected and scoreable that day', () => {
    const paused = taskFixture({ recurrenceHistory: pausedHistory() });
    const result = service.calculateDay(date('2026-03-10'), [
      { task: paused, occurrence: undefined, restDaysInWeekOrMonthUpToDate: [] },
    ]);
    expect(result).toBeNull();
  });
});
```

### 9.2 Teste do `RecurrenceRule` (`MONTHLY_DAY: 'LAST'` através de meses de tamanhos diferentes)

Ver [RecurrenceRule VO validation](issues/09-recurrence-rule-vo-validation.md) §"MONTHLY_DAY: 'LAST' test" — o caso decisivo é o par `2024-02-28 → false` / `2023-02-28 → true`, que expõe qualquer implementação ingênua que hardcode "dia 28".

---

## 10. Roadmap incremental

Fatias verticais, cada uma entregável e demonstrável de ponta a ponta:

1. **Tela principal ponta a ponta** (fatia 1): login Firebase, criar 1–2 tarefas simples (`DAILY`, sem `restPolicy`), calendário mensal com dia atual selecionado, slider com autosave, cor do dia recalculada. *Critério de pronto*: consigo abrir o app, marcar um dia, fechar, reabrir e ver o valor persistido e a cor certa — sem RLS, sem fotos, sem relatórios.
2. **Recorrência completa + cota de folga**: todos os `RecurrencePattern`, `RestPolicy`, `TaskRecurrenceHistory` versionado, pausas. *Pronto quando*: uma tarefa "academia 5x/semana" com 2 folgas/semana calcula corretamente ao longo de várias semanas, inclusive cruzando mês.
3. **Peso corporal**: tarefa de peso, ocorrência derivada de fechamento de mês, série temporal, componente de abertura/fechamento com cascata. *Pronto quando*: pesagens semanais alimentam o gráfico e o card de fechamento de mês mesmo com gaps.
4. **Visão anual + relatórios agregados**: grade de 12 meses, `isComplete`, contagem de folgas por mês/tarefa. *Pronto quando*: um ano com meses fechados mistos (alguns completos, mês corrente neutro) renderiza certo.
5. **Fotos**: upload, pipeline sharp, serving autenticado. *Pronto quando*: uma foto sobrevive resize/WebP/EXIF-strip e só é acessível autenticado.
6. **Timelapse + polimento final**: job diário FFmpeg, status endpoint, README, CI. *Pronto quando*: o pipeline de CI passa verde numa branch limpa e o vídeo do mês é gerado automaticamente.

---

## 11. README sugerido

```markdown
# Tracker Pessoal de Desempenho Diário

Um tracker de hábitos com uma regra central: **folga não é sinônimo de sucesso**. Cada
tarefa carrega seu peso e sua cota de dispensas legítimas; passar da cota pune o
desempenho do dia exatamente como faltar sem justificativa.

## Por que este projeto existe

Vitrine de arquitetura: Clean Architecture ponta a ponta (NestJS + Flutter), sem regra
de negócio vazando pra controller ou widget, ocorrências virtuais (nunca
pré-materializadas), fuso horário tratado como cidadão de primeira classe, e um
histórico que não muda de baixo dos seus pés quando você edita uma tarefa hoje.

## Stack
Backend: NestJS + TypeORM + Postgres + Firebase Auth · Frontend: Flutter (Web/Desktop)
+ flutter_modular + bloc + table_calendar + fl_chart · Docker + Portainer.

## Decisões de arquitetura que valem a leitura
Ver `docs/architecture.md` — em especial: por que não Row-Level Security, por que
RecurrenceRule é versionada em vez de imutável, e por que "folga dentro da cota"
mora num policy object separado do agregado Task.

## Rodando localmente
docker compose up — migrations rodam automaticamente no boot da API.
```

---

## 12. As 5 decisões mais discutíveis — defesa em entrevista

1. **Sem RLS no Postgres.** *Pergunta esperada*: "por que não usar defesa em profundidade?" *Defesa*: avaliei RLS e descartei conscientemente — o projeto tem uma única superfície de API e uma única fronteira de confiança; RLS defende contra um cenário (acesso via SQL direto/outro serviço) que não existe aqui. A defesa real é estrutural: `UserScopedRepository` torna fisicamente impossível montar uma query sem `userId`, testado por um contrato automatizado. Eu sei nomear o trade-off e escolhi não pagar a complexidade por um risco que não existe neste sistema.

2. **`RecurrenceRule` versionada em vez de imutável ou snapshot mensal.** *Pergunta esperada*: "por que não simplesmente congelar o mês quando ele fecha?" *Defesa*: um snapshot só age depois que o mês fecha — editar a recorrência no meio do mês corrente ainda mudaria o passado recente, o que é o bug real que a pergunta original queria evitar. Versionar a regra na fonte resolve isso em qualquer granularidade, sem tabela extra, reaproveitando campos que a regra já tinha.

3. **restPolicy dissocia frequência de recorrência.** *Pergunta esperada*: "isso não é gambiarra, misturar 'todo dia' com 'mas vale falhar 2x'?" *Defesa*: é separação deliberada de dois eixos ortogonais — "quando é esperado" (calendário puro, determinístico) vs. "quantas dispensas são legítimas" (pontuação). A alternativa (um pattern `WEEKLY_N_OF_7`) explodiria combinatorialmente pra cada variação de frequência-com-tolerância, e acoplaria o denominador do desempenho ao histórico de cumprimento — quebrando a determinística do cálculo.

4. **Nenhum SQL de agregação de data (`generate_series`, `date_trunc`).** *Pergunta esperada*: "por que não usar os recursos avançados do Postgres pra isso?" *Defesa*: dimensionei antes de otimizar — expandir um ano de recorrência em memória para um usuário único é da ordem de milhares de chamadas de função pura, microssegundos. Resolver isso em SQL duplicaria a lógica de `occursOn` numa segunda linguagem, arriscando divergência entre TypeScript e SQL, para ganhar performance que o problema não precisa.

5. **Ocorrência derivada de fechamento de peso não conta no denominador do dia.** *Pergunta esperada*: "por que não tratar como qualquer outra ocorrência esperada?" *Defesa*: é um lembrete gerado pelo sistema, não um compromisso que o usuário assumiu — contá-la puniria (ou premiaria) por algo que não fazia parte do contrato original da tarefa. `origin: DERIVED` isola essa semântica sem exigir uma segunda regra de cálculo: o serviço de desempenho só filtra por origem antes de montar o denominador.
