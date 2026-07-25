# Map: Personal Performance Tracker — Architecture Spec

## Destination

A complete, interview-defensible architecture spec for the personal daily-performance tracker (portfolio project), covering — in this order — architecture overview (Mermaid + end-to-end slider flow), domain model, data model (tables + first TypeORM migration), REST contract, monorepo folder structure, Flutter modules, infrastructure (Docker/compose/Portainer), security (user isolation in code), testing strategy (with a real test for the performance-calculation service and for RecurrenceRule), incremental roadmap by slices, and a suggested README. Ends at the document itself — no production code needs to be written beyond the illustrative snippets the spec already calls for.

## Notes

- Domain: personal daily-performance tracker, fixed stack (NestJS/TypeORM/Postgres + Flutter/Modular/Bloc), Clean Architecture on both sides, Firebase Auth.
- Business rules already locked by the user (do not reopen): day-performance formula (weighted average by `weight`), rest-day within/over quota (100%/0%, except tasks with no `restPolicy` → always 100%), week starts on Sunday (not ISO), unfilled day ≠ 0%, current month uncolored in the annual view (`isComplete`), colors are frontend-only, America/Sao_Paulo timezone, photos via sharp (resize ~1600px, WebP q≈85, strip EXIF), video via FFmpeg in a daily job deleting previous ones, Postgres in compose with healthcheck and migrations on boot.
- RecurrenceRule: the user's proposed design is the starting point (pure VO with `occursOn`, format version `v`, typed JSONB, startsOn/endsOn) — tickets here critique/correct it, not redesign it from scratch.
- When resolving each ticket, use `/grilling` and, when the question is domain modeling, `/domain-modeling`.
- Ticket work (this map, its tickets, discussion) is in English. The final architecture document (ticket 12) is written in Portuguese, per the original brief's explicit requirement — code identifiers stay in English either way.
- Convention: every resolved ticket should end with a clear recommendation + trade-off — that's what feeds the final document.
- The map's last ticket (composing the document) is deliberate execution, not a decision — it's the destination's materialization, done only once every decision tied to it above is closed.

## Decisions so far

- [User isolation strategy](issues/01-user-isolation-strategy.md) — no RLS; structural scoping via a base repository that can't build a query without `userId`, explicit propagation (no ambient state), plus one reusable cross-user isolation contract test run against every repository.
- [Virtual read performance](issues/02-virtual-read-performance.md) — no SQL-side recurrence expansion; one indexed range query + in-memory `occursOn` merge, cheap at this app's real scale. Monthly snapshot (if adopted in ticket 05) is an optional cache, not a required fix.
- [Calendar read contract](issues/03-calendar-read-contract.md) — split `GET /tasks` (cached, rarely refetched) from `GET /calendar/:year/:month` (refetched on month nav only, Sunday-padded); the slider's `PUT /occurrences/:taskId/:date` returns the updated occurrence + recomputed day performance so the client patches locally and never refetches the month after a drag.
- [Weekly quota placement](issues/04-weekly-quota-placement.md) — DAILY+restPolicy confirmed as clean separation (with a domain-glossary caveat on what "expected" means); quota check lives in a dedicated stateless `RestQuotaPolicy` service, not Task or the calc service; Sunday-week grouping is a pure in-memory function, no SQL.
- [Monthly snapshot for historical immutability](issues/05-monthly-snapshot-immutability.md) — no snapshot table; `RecurrenceRule` is versioned instead (ordered, non-overlapping validity windows reusing the VO's own startsOn/endsOn), fixing retroactive history changes even within an open month. Scope deliberately narrow: `restPolicy`/`weight` retroactivity stays an accepted, documented gap.
- [Exceptions and pauses](issues/06-exceptions-and-pauses.md) — in scope, made nearly free by the versioning above: a fifth `PAUSED` pattern variant (occursOn always false) reuses `TaskRecurrenceHistory` with no new entity or field.
- [Weight aggregate design](issues/07-weight-aggregate-design.md) — `weightKg` is a nullable field on `TaskOccurrence`, not a separate aggregate; recording a weight auto-derives `percentage = 100` (same three-state shape as every task); opening/closing month weight cascades backward to the most recent reading if the adjoining month is also empty, true-empty marker only when no reading exists at all.
- [Derived month-end weight occurrence](issues/08-derived-month-end-weight-occurrence.md) — deduped via `occursOn` set-membership on the last day (skipped if `PAUSED`); `origin: DERIVED` never enters the day's performance denominator (immutable metadata, doesn't affect the weight time series); signaled via `origin: 'RECURRENCE' | 'DERIVED'` on every calendar occurrence.
- [RecurrenceRule VO validation](issues/09-recurrence-rule-vo-validation.md) — `LocalDate` is a branded ISO string with pure free functions (not a class); final VO signature with the `PAUSED` variant; `MONTHLY_DAY: 'LAST'` test covers leap-Feb vs non-leap-Feb explicitly.
- [Photo pipeline](issues/10-photo-pipeline.md) — synchronous processing in the upload request (no queue), original never persisted (processed straight from an in-memory buffer), volume path mirrors the occurrence's own natural key, served via an authenticated endpoint reusing the User isolation strategy machinery (no signed URLs).
- [Timelapse video job](issues/11-timelapse-video-job.md) — no on-demand generation, only the automatic daily job; no streaming mechanism needed at all — a plain status endpoint (`READY`/`GENERATING`/`FAILED`/`NOT_YET_GENERATED`) queried when the reports screen opens is sufficient since no user session ever watches the job run live.
- [Timezone and persisted date](issues/13-timezone-and-persisted-date.md) — plain `DATE` columns everywhere (no `TIMESTAMPTZ`); one `ClockPort` adapter is the sole place that converts real time into `LocalDate` (America/Sao_Paulo, hardcoded, not per-user configurable); Flutter always waits for server-provided `serverToday`, never guesses from the device clock.
- [Compose architecture spec](issues/12-compose-architecture-spec.md) — materialized as [architecture-spec.md](architecture-spec.md), the destination itself.

## Not yet specified

- Integration test depth (testcontainers vs a dedicated test database in compose) — depends on how user isolation and RLS are resolved.
- CI pipeline detail (which jobs, lint/test/build, caching) — depends on the final monorepo structure.

## Deliberately not ticketed (composed directly in the final ticket, no decision of its own)

- Incremental roadmap and README: the brief already fixes slice 1 (main screen end-to-end); the rest is mechanical composition from decisions already made, not an open question.
- Monorepo folder structure and Flutter modules: follow the standard Clean Architecture / flutter_modular convention already fixed in the brief — no contestable point to resolve.
- Validating the 4 example goals (gym, entrepreneurship, diet, weight) against the model: a sanity check done while composing the final document, not a new decision — if one doesn't fit, that becomes a fresh ticket at that point.

## Out of scope

(none yet)
