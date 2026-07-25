Type: grilling
Status: resolved

## Question

Since occurrences are virtual, editing a task's `RecurrenceRule` in the future retroactively changes which past days were "expected" — and therefore changes historical percentages the user has already seen. Evaluate the proposed mitigation: when a month closes (`isComplete`), persist its aggregate into a monthly snapshot table, serving both as a freeze of history and as a read cache for the annual view. Is the complexity worth it, or is there a simpler alternative (e.g. versioning `RecurrenceRule` with a temporal validity window, always recalculating using the version in effect on each date)?

Resolve with the decision (monthly snapshot, rule versioning, or other) and how it relates to the strategy chosen in [Virtual read performance](../issues/02-virtual-read-performance.md).

## Answer

**No monthly snapshot. `RecurrenceRule` versioning instead — scoped to the recurrence rule only.**

**Why the snapshot alone doesn't work**: it only activates once a month closes (`isComplete`). A recurrence edit made mid-month still recomputes earlier days *of that same still-open month* against the new rule, retroactively changing percentages the user already saw within the current month — the exact failure mode the ticket is trying to prevent, just at a shorter time horizon. A snapshot table can't fix this because there's nothing to freeze yet at the time of the edit.

**Why versioning fixes it at the root**: instead of `Task` holding one mutable `RecurrenceRule`, it holds an ordered list of rule versions, each still using the VO's existing `startsOn`/`endsOn` fields as its validity window — no new fields needed, this reuses exactly the mechanism the brief already specified "so a task can be closed instead of deleted." Editing the recurrence closes the current version (`endsOn` = day before the edit's effective date) and appends a new version (`startsOn` = effective date, open-ended `endsOn`). Any date, past or present, always resolves against the version that was actually in effect on it — history never moves, whether the month is open or closed.

```typescript
class TaskRecurrenceHistory {
  constructor(private readonly versions: RecurrenceRule[]) {} // ordered by startsOn, non-overlapping

  occursOn(date: LocalDate): boolean {
    const version = this.versions.find(v => v.startsOn <= date && (!v.endsOn || date <= v.endsOn));
    return version?.occursOn(date) ?? false;
  }
}
```

`RecurrenceRule.occursOn` itself is untouched — still a pure, single-version method. `TaskRecurrenceHistory` is the thin selection layer in front of it; it's the piece that's new.

**Persistence**: the JSONB column becomes a JSONB **array** of versions instead of a single object (still validated at the boundary, still mapped to the VO list in the repository — no raw JSON reaches the domain). A write-time invariant enforces non-overlapping windows.

**Relation to [Virtual read performance](../issues/02-virtual-read-performance.md)**: no change to that strategy — the application-layer computation still does one indexed range query + in-memory expansion; it just calls `TaskRecurrenceHistory.occursOn` instead of a single rule's `occursOn`, which is the same cost class (still a pure in-memory lookup, now with one extra array scan over a handful of versions per task).

**Scope decision — deliberately narrow**: the same "editing changes the past" argument applies to `restPolicy` (quota) and `weight` (day's weighted average), since both are also live inputs to the performance formula. This ticket resolves `RecurrenceRule` only, per explicit scope choice — `restPolicy`/`weight` retroactivity is accepted as a known, undocumented-no-longer gap for this version: those fields are expected to change rarely, and the impact is judged acceptable for a personal-use portfolio project. Worth a one-line callout in the final domain-model deliverable so it reads as a conscious trade-off, not an oversight.

