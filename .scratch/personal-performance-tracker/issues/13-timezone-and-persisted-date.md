Type: grilling
Status: resolved

## Question

The brief explicitly asks: "define and document what gets persisted (local date vs UTC timestamp) and how 'today' is resolved in each layer," with a fixed America/Sao_Paulo timezone across all dates and the day boundary. This wasn't decided in any other ticket and affects the column type for `TaskOccurrence.date` (plain DATE vs truncated TIMESTAMPTZ), boundary validation (class-validator/zod), and how each layer resolves "today":
- Backend (NestJS): at what UTC time does the day roll over in Postgres, and where does that conversion happen (guard, interceptor, domain service)?
- Frontend (Flutter Web/Desktop): the device clock might be in another timezone — how does the app resolve "today" without blindly trusting the local `DateTime.now()`?
- Postgres: column type and behavior in `generate_series`/aggregations (relevant to [Virtual read performance](../issues/02-virtual-read-performance.md) and [Weekly quota placement](../issues/04-weekly-quota-placement.md)).

Resolve with the persisted data type, the exact timezone-conversion point in each layer, and a note on the user changing timezones (out of scope, or supported?).

Note from [RecurrenceRule VO validation](09-recurrence-rule-vo-validation.md): `LocalDate` is a branded ISO string (`YYYY-MM-DD`), not a class — this ticket should settle where a raw `Date`/timestamp gets converted into that branded string (and back) at each layer's boundary, since the VO itself never touches real timezones once it has one.

## Answer

**Persisted type: plain Postgres `DATE`, not `TIMESTAMPTZ`.** `TaskOccurrence.date` (and every other date column: `Task.startsOn`/`endsOn`, `RecurrenceRule` version boundaries) is a bare `DATE` — no time component, no timezone, ever. This isn't a stylistic choice: `TIMESTAMPTZ` would reintroduce exactly the UTC-midnight-vs-local-midnight ambiguity the brief is trying to eliminate. TypeORM's `date` column type is configured to return plain strings (not JS `Date` objects) so a row read maps directly onto the branded `LocalDate` string with no conversion step — the boundary mapping is "trust the string," not "parse and reformat."

**The one and only timezone-conversion point, backend side**: a small `ClockPort` in the application layer, with a single method `today(): LocalDate`, implemented by a `SaoPauloClockAdapter` using `Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' })` to format the current instant (`new Date()`, i.e. real UTC-backed system time) directly into a `YYYY-MM-DD` string (the `en-CA` locale happens to format that way natively, no manual string surgery needed). Every use case that needs "today" (deriving the month-end weight occurrence, deciding `isComplete` for a month, defaulting the calendar view) is injected this port — never calls `new Date()` or reads the system clock directly. This makes "today" trivially fakeable in tests (a `FixedClock` returning a hardcoded `LocalDate`) and keeps the conversion to exactly one adapter in the whole codebase.

**Frontend (Flutter): "today" is always server-provided, never a local guess.** `GET /calendar/:year/:month` includes a `serverToday: LocalDate` field (produced by the same `ClockPort`). On cold app load, the UI shows a loading state until this first response arrives, then selects `serverToday` — it never reads `DateTime.now()` from the device to decide which day is "today" for anything that affects scoring or the initially-selected day. This is consistent with the app's already-locked "no offline cache, connection always available" assumption: there's no responsiveness case being traded away, only a correctness risk (a device with a misconfigured or foreign timezone momentarily highlighting the wrong day) being removed for free.

**Postgres/`generate_series`**: moot by construction — [Virtual read performance](../issues/02-virtual-read-performance.md) already ruled out any SQL-side date generation or `date_trunc`. The only SQL involving dates is a plain `WHERE date BETWEEN $1 AND $2` range filter on a `DATE` column, which has no timezone semantics to get wrong.

**User changing timezones: explicitly out of scope, by the brief's own fixed rule.** "All dates and the day boundary use America/Sao_Paulo" is stated as a hard, non-per-user rule — there's no per-user timezone preference to store or honor. If the user travels, the app's day boundary stays anchored to America/Sao_Paulo regardless of the device's actual location; `ClockPort`'s timezone is a hardcoded constant (`const APP_TIMEZONE = 'America/Sao_Paulo'`), not a configuration knob, since nothing else in the domain (recurrence rules, week-start-Sunday grouping) is designed to vary per user either.

