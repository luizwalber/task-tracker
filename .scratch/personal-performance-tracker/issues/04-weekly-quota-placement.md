Type: grilling
Status: resolved

## Question

The user proposed solving "gym 5x/week" as a `DAILY` task + `restPolicy: { count: 2, per: 'WEEK' }`, moving frequency semantics from the recurrence into the scoring policy. Critique this choice: is it a clean separation of concerns or disguised coupling? And where exactly should the quota check live — in the performance-calculation service, in a dedicated policy object (e.g. `RestPolicyEvaluator`), or in the `Task` aggregate? Also decide: how does the weekly quota handle a week that spans a month boundary (the quota belongs to the week even if it falls across two months) — which Sunday-week grouping approach in SQL is correct and indexable (explicit offset, computed column, or grouping in the application layer)?

Resolve with a verdict on where the quota lives, the responsible object/service, and the chosen Sunday-week grouping strategy with justification.

## Answer

**Verdict on DAILY + restPolicy: clean separation, not disguised coupling — with one caveat.** Recurrence answers "which days does this pattern touch" as a pure calendar function; restPolicy answers "how many dismissals are legitimate," a scoring concern layered on top. Folding "5x/week" into a dedicated `WEEKLY_N_OF_7`-style pattern would require a combinatorial explosion of pattern types for every frequency-with-tolerance shape, and would make "days expected" depend on historical fulfillment rather than being a deterministic calendar fact — which is exactly the property the performance-calculation denominator needs. The caveat: "expected" in this system does **not** mean "a commitment the user made for that specific day" — it means "counts toward the denominator, subject to rest-day override." That's a deliberate technical redefinition of an ordinary word, so it must be called out explicitly in the domain glossary (final domain-model deliverable), not left implicit — otherwise a reader will misread `occursOn` returning `true` every day for a gym task as the app expecting a workout literally every day.

**Where the quota check lives: a dedicated stateless domain service, `RestQuotaPolicy`** — not a `Task` method, not buried in the performance-calculation service. It cannot be a pure single-date method like `RecurrenceRule.occursOn` because it needs the period's other rest-days to know whether this one is still within quota — but it stays I/O-free: the caller (the performance-calculation service) is responsible for gathering the period's rest-day dates first, and `RestQuotaPolicy` just evaluates them.

```typescript
class RestQuotaPolicy {
  // restDaysInPeriodUpToDate: every rest-day date for this task in the same
  // restPolicy period (week or month), sorted ascending, including `date` itself.
  evaluate(policy: RestPolicy | undefined, restDaysInPeriodUpToDate: LocalDate[], date: LocalDate): 'WITHIN_QUOTA' | 'OVER_QUOTA' {
    if (!policy) return 'WITHIN_QUOTA'; // no restPolicy → every rest day scores 100%
    const ordinal = restDaysInPeriodUpToDate.indexOf(date) + 1; // 1-based position of this rest day in the period
    return ordinal <= policy.count ? 'WITHIN_QUOTA' : 'OVER_QUOTA';
  }
}
```

Kept separate from `Task` because it doesn't need any other task state, and separate from the calc service because it's independently unit-testable as one invariant (see testing-strategy deliverable) rather than buried in a larger orchestration test.

**Sunday-week grouping: application layer, no SQL.** Consistent with [Virtual read performance](../issues/02-virtual-read-performance.md) — no `date_trunc` (Monday-based, wrong for this domain), no computed column, no dedicated index. A pure function `startOfWeekSunday(date: LocalDate): LocalDate` groups already-fetched occurrence dates in memory. No SQL grouping key is ever needed because there's no SQL-side aggregation in this design.

**Month-boundary practical detail**: because the calendar month read ([Calendar read contract](../issues/03-calendar-read-contract.md)) fetches by calendar-month bounds, a week's quota that spans two months needs a few extra days of context. Fix: `GET /calendar/:year/:month` fetches occurrences for the Sunday-aligned range that *contains* the month (i.e., padded out to the full weeks touching the first and last day of the month, up to 6 extra days on each side) — the quota evaluation for boundary-crossing weeks sees the whole week, while only the days inside the actual calendar month are rendered as cells.

