Type: grilling
Status: resolved

## Question

Validate/correct/complete the proposed `RecurrenceRule` design (pure VO with a single `occursOn(date: LocalDate): boolean` method, format version `v`, `pattern` union of `DAILY | WEEKLY_DAYS | MONTHLY_DAY | INTERVAL`, `startsOn`/`endsOn`, persisted as typed JSONB with validation at the boundary). Specific points to cover: `MONTHLY_DAY` with `day: 'LAST'` must work correctly across 28/29/30/31-day months — design the test that covers this; the rule must operate only on local America/Sao_Paulo dates, never `Date`/UTC — confirm how the weekday is derived without going through a timezone conversion.

Resolve with the final VO design (TypeScript signature) and the `MONTHLY_DAY: 'LAST'` test case. The exact `LocalDate` representation (persisted type, timezone conversion point) is decided in [Timezone and persisted date](../issues/13-timezone-and-persisted-date.md) — here, assume `LocalDate` already arrives as a local date with no time component.

Note from [Monthly snapshot for historical immutability](../issues/05-monthly-snapshot-immutability.md): `Task` now holds an ordered, non-overlapping list of `RecurrenceRule` versions (using the VO's own `startsOn`/`endsOn` as each version's validity window) instead of a single rule, selected through a `TaskRecurrenceHistory` wrapper before `occursOn` is called. This ticket's job is still just the single-version VO itself — `TaskRecurrenceHistory` and the non-overlap invariant are already designed, not open questions here.

Note from [Exceptions and pauses](../issues/06-exceptions-and-pauses.md): the `pattern` union gets a fifth variant, `{ type: 'PAUSED' }`, whose `occursOn` always returns `false` — include it in the final VO signature and its validation schema.

## Answer

**`LocalDate` representation: a branded ISO string, not a class.** `type LocalDate = string & { __brand: 'LocalDate' }`, format `YYYY-MM-DD`. It serializes/deserializes for free (it's already what JSON and Postgres `DATE` produce), compares with native `<`/`>`/`===` because ISO format sorts lexicographically identical to chronologically, and needs no allocation. Date arithmetic lives in pure free functions next to the VO, not as instance methods — `dayOfWeek(date): Weekday`, `addDays(date, n): LocalDate`, `lastDayOfMonth(date): LocalDate`, all implemented via `Date.UTC(y, m, d)` constructed from the string's own numeric parts and read back with `getUTCDay()`/`getUTCDate()` — UTC methods only ever touch the numbers already in the string, so no real timezone is ever consulted, sidestepping the whole DST/offset class of bugs.

**Final VO**:

```typescript
type Weekday = 'SUN' | 'MON' | 'TUE' | 'WED' | 'THU' | 'FRI' | 'SAT';
type LocalDate = string & { __brand: 'LocalDate' };

type RecurrencePattern =
  | { type: 'DAILY' }
  | { type: 'WEEKLY_DAYS'; days: Weekday[] }
  | { type: 'MONTHLY_DAY'; day: number | 'LAST' }
  | { type: 'INTERVAL'; everyNDays: number }
  | { type: 'PAUSED' }; // occursOn always false — see Exceptions and pauses

class RecurrenceRule {
  readonly v: 1 = 1;
  constructor(
    readonly pattern: RecurrencePattern,
    readonly startsOn: LocalDate,
    readonly endsOn?: LocalDate,
  ) {}

  occursOn(date: LocalDate): boolean {
    if (date < this.startsOn) return false;
    if (this.endsOn && date > this.endsOn) return false;
    switch (this.pattern.type) {
      case 'DAILY': return true;
      case 'PAUSED': return false;
      case 'WEEKLY_DAYS': return this.pattern.days.includes(dayOfWeek(date));
      case 'MONTHLY_DAY': return this.matchesMonthlyDay(date);
      case 'INTERVAL': return daysBetween(this.startsOn, date) % this.pattern.everyNDays === 0;
    }
  }

  private matchesMonthlyDay(date: LocalDate): boolean {
    const { day } = this.pattern as { type: 'MONTHLY_DAY'; day: number | 'LAST' };
    return day === 'LAST' ? date === lastDayOfMonth(date) : dayOfMonth(date) === day;
  }
}
```

**`MONTHLY_DAY: 'LAST'` test — the one that must pass across 28/29/30/31-day months**:

```typescript
describe('RecurrenceRule: MONTHLY_DAY LAST across month lengths', () => {
  const rule = new RecurrenceRule({ type: 'MONTHLY_DAY', day: 'LAST' }, '2024-01-01' as LocalDate);

  it.each([
    ['2024-01-31', true],  // 31-day month
    ['2024-01-30', false],
    ['2024-04-30', true],  // 30-day month
    ['2024-04-29', false],
    ['2024-02-29', true],  // leap Feb — 29 days
    ['2024-02-28', false], // NOT last day in a leap year
    ['2023-02-28', true],  // non-leap Feb — 28 days
    ['2023-02-27', false],
  ])('occursOn(%s) === %s', (date, expected) => {
    expect(rule.occursOn(date as LocalDate)).toBe(expected);
  });
});
```

The `2024-02-28 → false` / `2023-02-28 → true` pair is the case that actually exercises leap-year logic — a naive `day === 28` check would pass the non-leap case and silently fail the leap one.

