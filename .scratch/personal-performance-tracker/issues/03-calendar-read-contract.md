Type: grilling
Status: resolved

## Question

Should the monthly calendar read contract be a single endpoint returning the whole month (days + tasks + existing records), or separate endpoints (user's tasks, month's records, aggregated summary)? Think especially about the re-fetch cost after every slider autosave (functional requirement 3) — does a single large payload force a full refetch on every drag, or does the autosave update only local state without triggering a refetch?

Resolve with the read endpoint(s) for the month and their relationship to the occurrence upsert.

## Answer

**Two endpoints, split by change frequency, not by resource type alone:**

- `GET /tasks` — the user's active tasks (name, recurrence, weight, restPolicy, type). Changes only when the user edits/creates/ends a task — rare, outside the daily flow. The client fetches this once per session/app-load and caches it; month navigation never re-triggers it.
- `GET /calendar/:year/:month` — the month's days, each with an aggregate performance (or `null` for not-yet-computed/future days), plus the recorded occurrences that exist for that month (so opening any day reveals its per-task state instantly, no per-day round trip). Re-fetched on month navigation only.

**Relationship to the slider autosave**: the upsert is `PUT /occurrences/:taskId/:date` (idempotent, keyed by `userId + taskId + date`, not a synthetic id — matches the virtual-occurrence model). Its response returns the updated occurrence **and** the recomputed performance for that single day. The client patches its local day-state and the calendar cell color from that response directly — it never re-fetches `GET /calendar/:year/:month` after a drag. This is what keeps the drag-to-save loop fast: one write request per debounced drag, zero reads.

**Why not one combined endpoint**: a single `GET /calendar/:year/:month` returning tasks too would force re-fetching the (rarely-changing) task list on every month navigation, and would tie the task list's cache lifetime to the month view's — splitting them lets the client treat tasks as long-lived reference data and the month view as the only thing that's frequently refreshed.

**Amendment from [Weekly quota placement](04-weekly-quota-placement.md)**: `GET /calendar/:year/:month` actually fetches a Sunday-aligned range padded to cover the full weeks touching the month's first/last day (up to 6 extra days per side), so week-spanning rest-quota evaluation has full context — only days inside the actual calendar month are returned as renderable cells.

**Amendment from [Timezone and persisted date](13-timezone-and-persisted-date.md)**: the response also includes `serverToday: LocalDate`, produced by the backend's `ClockPort` — Flutter uses this (never the device clock) to decide which day is initially selected, so the response shape is `{ serverToday, days: [...] }`.

