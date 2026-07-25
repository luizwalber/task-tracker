Type: grilling
Status: resolved

## Question

The annual view expands recurrences and aggregates ~365 days of virtual occurrences per task. What read strategy avoids reprocessing everything on each request — SQL aggregation, `generate_series`, a monthly snapshot (see [Monthly snapshot for historical immutability](../issues/05-monthly-snapshot-immutability.md)), or a combination — and what's the fallback plan if the primary strategy doesn't scale (more tasks, more years of history)? Consider the cost of expanding `RecurrenceRule.occursOn` per day vs per task vs in batch.

Resolve with the chosen strategy, the reasoning, and the fallback plan.

## Answer

**Challenging the framing first**: `RecurrenceRule.occursOn` is a pure in-memory TS function — it cannot run inside Postgres without duplicating recurrence logic in SQL, which would break the "pure, 100% unit-testable VO" principle already locked in for RecurrenceRule. And at this app's real scale (single user, a few dozen tasks at most, a handful of years of history), expanding a year of dates against a handful of tasks is on the order of a few thousand pure function calls — microseconds, not a performance problem. Reaching for `generate_series`/SQL-side aggregation here would be solving a bottleneck that doesn't exist, at the cost of a second implementation of the recurrence rule that can drift from the domain one.

**Chosen strategy — application-layer computation, SQL stays dumb:**

1. One indexed range query fetches recorded occurrences for the period: `SELECT * FROM task_occurrences WHERE user_id = $1 AND date BETWEEN $2 AND $3` — served by the same `(user_id, task_id, date)` unique index the upsert already needs (see data model ticket, still pending).
2. For each task active in the range, `RecurrenceRule.occursOn(date)` is called once per date in memory to build the set of expected days — no I/O, no SQL involvement.
3. The domain performance-calculation service merges (2) against (1): expected-but-unrecorded days are "unfilled" (excluded, not 0%), recorded days apply the weighted-average/rest-quota rules already locked in.
4. This same three-step read powers both the monthly view (range = 1 month) and the annual view (range = 1 year, run once per month-in-range, or once for the whole year and then bucketed by month in the application).

**Update from [Monthly snapshot for historical immutability](../issues/05-monthly-snapshot-immutability.md)**: no snapshot table was adopted — the immutability problem was solved instead by versioning `RecurrenceRule` with validity windows, which this strategy already accommodates (step 2 just calls the versioned `occursOn` selector instead of a single rule's). The annual view recomputes all 12 months live on every request — still cheap at this scale (~365 days × task count, still microseconds).

**Fallback plan (plan B)**, only if usage ever genuinely outgrows this (multi-user SaaS pivot, decades of history): introduce a monthly snapshot table at that point as mandatory precomputation (a nightly job materializes any month that just closed), so the annual view never recomputes closed months regardless of total history length — only the current open month (≤31 days) stays live. No path in this plan ever pushes recurrence evaluation into SQL.

