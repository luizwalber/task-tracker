Type: grilling
Status: resolved

## Question

Task exceptions and pauses (travel, injury — periods where a task shouldn't count as expected nor consume a rest-day slot): can this be modeled now without bloating the `RecurrenceRule` value object, or is it out of scope for this version? If in scope, where does it live (a new field on `Task`, a separate `TaskPause` entity, or reusing `endsOn`/a new `startsOn` by closing and reopening the task)? If out of scope, record it as explicit out-of-scope with the reason.

Resolve with a scope decision (in or out) and, if in, the minimal design.

## Answer

**In scope — made cheap by [Monthly snapshot for historical immutability](05-monthly-snapshot-immutability.md)'s `RecurrenceRule` versioning.** Since `Task` already holds an ordered, non-overlapping list of rule versions selected by validity window (`TaskRecurrenceHistory`), a pause is just another version, not a new concept:

```typescript
type RecurrencePattern =
  | { type: 'DAILY' }
  | { type: 'WEEKLY_DAYS'; days: Weekday[] }
  | { type: 'MONTHLY_DAY'; day: number | 'LAST' }
  | { type: 'INTERVAL'; everyNDays: number }
  | { type: 'PAUSED' }; // occursOn always returns false
```

Starting a pause (travel, injury) closes the current version (`endsOn` = day before the pause starts) and inserts a `PAUSED` version for the pause window; ending the pause closes that version and reopens a new one with the original pattern. No new entity, no new field on `Task`, no change to the performance-calculation service: a `PAUSED` day is simply not "expected" — same treatment as a day before `startsOn` or after `endsOn` — so it's excluded from both the day's denominator and the rest-day quota count, exactly as required.

**Minimal addition needed beyond ticket 05's design**: `PAUSED` is a fifth pattern variant with no fields and a trivial `occursOn`, and the UI needs a "pause this task" action that creates the version transition — otherwise the versioning machinery from ticket 05 already carries the whole feature.

