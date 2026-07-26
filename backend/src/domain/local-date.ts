export type LocalDate = string & { readonly __brand: 'LocalDate' };

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

export function toLocalDate(value: string): LocalDate {
  if (!ISO_DATE.test(value)) {
    throw new Error(`Invalid LocalDate: ${value}`);
  }
  return value as LocalDate;
}

export function addDays(date: LocalDate, days: number): LocalDate {
  const [y, m, d] = date.split('-').map(Number);
  const utc = new Date(Date.UTC(y, m - 1, d));
  utc.setUTCDate(utc.getUTCDate() + days);
  return toLocalDate(utc.toISOString().slice(0, 10));
}

export function dayOfWeek(date: LocalDate): number {
  const [y, m, d] = date.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay(); // 0 = Sunday
}

export function firstDayOfMonth(year: number, month: number): LocalDate {
  return toLocalDate(`${year}-${String(month).padStart(2, '0')}-01`);
}

export function lastDayOfMonth(year: number, month: number): LocalDate {
  const utc = new Date(Date.UTC(year, month, 0));
  return toLocalDate(utc.toISOString().slice(0, 10));
}

export function startOfWeekSunday(date: LocalDate): LocalDate {
  return addDays(date, -dayOfWeek(date));
}
