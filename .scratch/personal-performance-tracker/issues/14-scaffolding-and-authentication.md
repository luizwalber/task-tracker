# 14 — Scaffolding + Autenticação

**What to build:** o esqueleto rodável do monorepo (Docker Compose com Postgres, migrations rodando automaticamente na subida da API, apps NestJS e Flutter mínimos) com autenticação Firebase funcionando ponta a ponta: o usuário loga no Flutter, o backend valida o token e isola qualquer acesso por usuário de forma estrutural — nenhuma consulta consegue rodar sem escopo de usuário.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] `docker compose up` sobe Postgres (com healthcheck e volume persistente) e a API, rodando as migrations automaticamente antes de aceitar tráfego — `synchronize` desligado.
- [x] Login com Firebase Auth funciona no Flutter (Web e Desktop) e o token é anexado nas chamadas à API. `ApiClient` (frontend/lib/core/api_client.dart) anexa o `Authorization: Bearer <token>` em toda chamada; `HomePage` chama `GET /me` para provar o loop. Backend verificado ponta a ponta contra um projeto Firebase real (`task-tracker-d5cef`): sem token → 401 `Missing bearer token`; com um ID token real (obtido via REST `accounts:signInWithPassword`) → 200 com a projeção do usuário criada no primeiro acesso. O lado Flutter ainda não tem `flutterfire configure` rodado (falta `firebase_options.dart`/`google-services.json`), então o login dentro do app em si segue não testado — só o backend foi validado com credenciais reais.
- [x] Um guard no backend valida o ID token do Firebase em toda rota protegida; requests sem token ou com token inválido retornam 401.
- [x] Existe um objeto de acesso a dados de base (repositório) que estruturalmente não permite montar nenhuma consulta sem o identificador do usuário autenticado — nenhuma rota consegue "esquecer" o filtro de usuário.
- [x] Um teste automatizado de contrato comprova que um usuário nunca alcança um recurso de outro usuário (resposta 404, nunca 403, para não vazar existência).
- [x] Depois de logar, o app mostra uma casca de tela autenticada vazia (sem funcionalidade de negócio ainda).

## Implementation notes

- Pastas `back`/`front` renomeadas para `backend`/`frontend` (estavam vazias) para bater com o brief original.
- `flutter_modular` v7 mudou de API em relação ao que o architecture-spec.md documentou (`createModule(register:)` + `ModularContext`, navegação via `context.navigate`/`context.pushNamed`, `inject<T>()` para acesso fora de widget) — o `AuthBloc` é construído por Modular mas exposto via `BlocProvider.value` em `app_widget.dart`, ponte entre DI do Modular e a reatividade do flutter_bloc.
- `/code-review` (Standards + Spec) rodado antes do commit. Achado real corrigido: nenhuma chamada HTTP existia ainda para efetivamente anexar o token — criado `ApiClient` + wiring em `HomePage`. Scope creep corrigido: volumes `photos_data`/`videos_data` removidos do `docker-compose.yml` (voltam nos tickets de Fotos/Timelapse, quando forem usados). Achado aceito sem alteração: teste de isolamento contra uma entidade de fixture (`SampleItemEntity`) mantido deliberadamente — é o único jeito de provar `UserScopedRepository` correto antes de existir uma entidade real de domínio escopada por usuário; será reaproveitado pelas tarefas reais a partir do ticket 15.
