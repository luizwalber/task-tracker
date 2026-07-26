# 15 — Tela principal ponta a ponta

**What to build:** o loop central do app: cadastrar uma tarefa simples, ver o calendário do mês atual com o dia de hoje já selecionado, e marcar o desempenho do dia arrastando um slider que salva sozinho. Recorrência fica limitada a "todo dia" nesta fatia — os demais padrões de recorrência, cota de folga e pausas entram em tickets seguintes.

**Blocked by:** 14 — Scaffolding + Autenticação.

**Status:** done

- [x] O usuário cria, lista e edita uma tarefa (nome, peso de 0.5 a 2, tipo comum, data de início, data de término opcional) — recorrência fixa em "todo dia" nesta fatia.
- [x] Ao abrir o app, o calendário do mês atual aparece com o dia de hoje já selecionado; um clique seleciona outro dia.
- [x] Selecionar um dia revela as tarefas esperadas naquele dia, cada uma com seu slider de 10 em 10%.
- [x] Arrastar o slider salva automaticamente (sem botão de confirmar), com debounce, feedback visual de "salvando"/"salvo", e o valor arrastado nunca se perde se a rede falhar durante o salvamento.
- [x] O endpoint de salvamento é um upsert idempotente, chaveado por usuário + tarefa + data (não por id sintético), e devolve o percentual recalculado do dia na própria resposta — o cliente não refaz a busca do mês inteiro após o autosave.
- [x] A célula de cada dia no calendário é colorida conforme o desempenho agregado daquele dia; um dia ainda não preenchido aparece em branco, visualmente distinto de um dia com 0%.
- [x] Fechar e reabrir o app preserva os valores já registrados (persistido no Postgres via upsert; `GET /calendar` relê do banco a cada abertura).

## Implementation notes

Backend: `Task`/`TaskOccurrence` domain entities with recurrence hardcoded to "every day" (`startsOn`/`endsOn`, no `RecurrenceRule`/versioning yet — ticket 16), `PerformanceCalculationService` (weighted average, unfilled excluded), `TaskRepository`/`TaskOccurrenceRepository` (TypeORM), `GetCalendarMonthUseCase` (Sunday-padded weeks, in-memory), `UpsertOccurrenceUseCase` (idempotent by userId+taskId+date, returns recomputed day performance). New migration for `tasks`/`task_occurrences`. `EnsureUserProjectionUseCase` is called from `TaskController.create` and `OccurrenceController.upsert` before any FK-dependent write, since task/occurrence rows reference `users(id)`. `ValidationPipe` moved to an `APP_PIPE` provider in `AppModule` (not `main.ts`) so it also applies inside Nest `TestingModule`-based integration tests.

Frontend: `task` module (`TaskCubit` for list/create/update) and `calendar` module (`CalendarBloc` — debounces slider drags per taskId via internal `Timer`s, never reverts an optimistic value on a failed save). `CalendarPage` replaces `HomePage` at the `/home` route — the home module (ticket 27's placeholder, explicitly documented as temporary until "the calendar/task modules land in later tickets") was deleted as dead code once superseded. Month grid and slider list are hand-rolled widgets (no `table_calendar`/new pubspec dependency) to keep the diff self-contained.

Deferred to later tickets, per the map: month navigation (prev/next), `RecurrenceRule` patterns beyond DAILY, `RestPolicy`/quota, pauses, weight tasks, photos, reports, timelapse.

`/code-review` (Standards + Spec, 2 parallel passes) run before closing. Real findings corrected:
- **No UI reached task edit/list** — `TaskCubit.update`/`ListTasksUseCase` existed but only task *creation* was wired to a button. Renamed `CreateTaskDialog` to `TaskFormDialog` (shared create/edit form, prefilled when given an `editingTask`), added `TaskListDialog` ("Minhas tarefas") as the entry point that lists tasks and opens the form in edit mode. Now the AC1 checkbox ("cria, lista e edita") is actually reachable end-to-end, not just backend-complete.
- **`CalendarBloc` seeded the initial month fetch from the device clock** — violated the locked [Timezone and persisted date](issues/13-timezone-and-persisted-date.md) decision ("Flutter sempre espera `serverToday` do servidor, nunca chuta a partir do device clock"). Fixed: the device clock only seeds the *first* network call; if the returned `serverToday` lands in a different month, the bloc immediately refetches using the server's own month before ever rendering.
- **Occurrence upsert was check-then-insert** (`repo.save()` on a fully-keyed entity), not the atomic `INSERT ... ON CONFLICT` the natural-key upsert contract implies for concurrent writes to the same key. Fixed using TypeORM's `Repository.upsert(entity, ['userId','taskId','date'])`.
- **Duplicated join logic** between `UpsertOccurrenceUseCase` and `GetCalendarMonthUseCase` (pairing each task with its occurrence on a date) — extracted to `application/performance/build-day-performance-inputs.ts`, shared by both.
- **Retry claim without retry code** — `task_slider_tile.dart` said "tentando de novo" on a failed save, but `CalendarBloc` never actually retried. Rather than soften the copy, implemented the single bounded automatic retry the architecture-spec's flow diagram (§1.2) already documents — capped at one attempt so a persistently-down network doesn't retry forever; the next drag starts a fresh attempt regardless.

Findings noted but not changed: a few Fowler-baseline judgement calls (e.g. `_isSameDay` duplicated across three frontend files, hand-rolled ISO-date formatting duplicated between two repository impls) — accepted as-is at this size; worth revisiting if a `LocalDate`-equivalent frontend type or a shared calendar-math helper earns its keep in a later ticket.
