# 25 — Uma lista de entidades só, não duas

**What to build:** `data-source.ts` (migrations/CLI) e `app.module.ts` (a API em runtime) passam a ler a lista de entidades TypeORM de um único lugar exportado, em vez de cada um declarar sua própria cópia.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] Existe um único ponto (`backend/src/infrastructure/persistence/entities.ts`) que exporta a lista de entidades TypeORM do projeto.
- [x] `data-source.ts` importa essa lista em vez de declarar a sua própria.
- [x] `app.module.ts` (dentro do `TypeOrmModule.forRootAsync`) importa a mesma lista em vez de declarar a sua própria.
- [x] Adicionar uma nova entidade no futuro é uma mudança em um arquivo só, não em dois.
- [x] Suite de testes do backend (3 unit + 6 integração), `npm run build` e `tsc --noEmit` continuam passando sem alteração de comportamento.

## Implementation notes

`/code-review` (Standards + Spec) rodado antes de fechar — sem achados acionáveis. Duas observações registradas sem necessidade de ação: (1) `data-source.ts` e `app.module.ts` ainda montam a mesma forma de opções TypeORM (`type/url/entities/synchronize`) de dois jeitos diferentes de ler a config (`dotenv` vs `ConfigService`) — padrão comum e defensável na separação Nest DI / TypeORM CLI, não o que este ticket visava resolver; (2) `entities.ts` com um item só é antecipatório por natureza — é exatamente o que o ticket pediu (pagar o custo agora, barato, em vez de depois).
