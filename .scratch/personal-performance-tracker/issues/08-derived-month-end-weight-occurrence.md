Type: grilling
Status: resolved
Blocked by: 07

## Question

The domain should inject a derived occurrence of the weight task on the last day of the month, as a month-close weigh-in reminder. Resolve: (1) how to avoid duplicating it when the last day of the month already falls on a day the weekly recurrence covers — in that case the weekly occurrence should already absorb the closing role; (2) confirm (or argue against) that this derived occurrence does not enter the day's performance denominator, since it's a system-generated reminder rather than a commitment the user took on; (3) how the API signals the origin (`origin: 'RECURRENCE' | 'DERIVED'`) so Flutter can render it with a different visual treatment.

Depends on [Weight aggregate design](../issues/07-weight-aggregate-design.md) because how weight is modeled (own aggregate vs field on the occurrence) affects where the derived occurrence pulls its value from.

Resolve with the three decisions above.

## Answer

**(1) Dedup**: at virtual-occurrence generation time (the same expansion step from [Virtual read performance](../issues/02-virtual-read-performance.md)), compute the weight task's normal recurrence-based dates via `TaskRecurrenceHistory.occursOn` first. If the month's last day is already in that set, do nothing — the weekly occurrence already covers closing duty. If it isn't (and the task isn't `PAUSED`/outside its `startsOn`–`endsOn` on that date — a paused task gets no reminder either, consistent with a pause meaning "not tracked at all"), inject one extra virtual occurrence for that date, tagged `origin: 'DERIVED'`. This works for any recurrence pattern, not just `WEEKLY_DAYS`, since it's a set-membership check on `occursOn`'s output, not a hardcoded weekly rule.

**(2) Confirmed: excluded from the day's performance denominator.** Only `origin: 'RECURRENCE'` occurrences count as "expected" in the weighted-average calculation — `origin: 'DERIVED'` never does, regardless of whether the user ends up filling it in. This is orthogonal to the weight time series: if the user does record a weight on the derived day, that reading still counts for the month-close/open weight display ([Weight aggregate design](07-weight-aggregate-design.md) — "last reading recorded within that month" doesn't care about origin), it just doesn't move that day's completion percentage. `origin` is immutable metadata describing *why* the occurrence was surfaced, not whether it was fulfilled — a filled-in derived occurrence stays tagged `DERIVED` rather than being promoted to `RECURRENCE`.

**(3) API signaling**: every occurrence returned by `GET /calendar/:year/:month` (recorded or still-unfilled placeholder) for the weight task carries `origin: 'RECURRENCE' | 'DERIVED'`. Flutter uses this to render the derived reminder with a distinct visual treatment (e.g., a subdued badge) and to exclude it from any client-side display of "tasks due today" that implies a commitment, separate from a badge that says "consider weighing in — month is closing."

