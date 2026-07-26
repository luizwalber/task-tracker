import { PerformanceCalculationService } from './performance-calculation.service';
import { Task } from '../task/task.entity';
import { TaskOccurrence } from '../occurrence/task-occurrence.entity';
import { toLocalDate } from '../local-date';

function taskFixture(overrides: Partial<ConstructorParameters<typeof Task>[0]> = {}) {
  return new Task({
    id: 't1',
    userId: 'user-a',
    name: 'Gym',
    weight: 1,
    startsOn: toLocalDate('2026-01-01'),
    ...overrides,
  });
}

function occurrenceFixture(overrides: Partial<ConstructorParameters<typeof TaskOccurrence>[0]> = {}) {
  return new TaskOccurrence({
    userId: 'user-a',
    taskId: 't1',
    date: toLocalDate('2026-03-10'),
    percentage: 100,
    ...overrides,
  });
}

describe('PerformanceCalculationService', () => {
  const service = new PerformanceCalculationService();
  const date = toLocalDate('2026-03-10');

  it('returns null when no task is expected that day', () => {
    const notYetStarted = taskFixture({ startsOn: toLocalDate('2026-04-01') });
    const result = service.calculateDay(date, [{ task: notYetStarted, occurrence: undefined }]);
    expect(result).toBeNull();
  });

  it('excludes an unfilled expected task from the average, not as 0%', () => {
    const gym = taskFixture({ id: 'gym', weight: 1 });
    const diet = taskFixture({ id: 'diet', weight: 1 });
    const result = service.calculateDay(date, [
      { task: gym, occurrence: undefined },
      { task: diet, occurrence: occurrenceFixture({ taskId: 'diet', percentage: 80 }) },
    ]);
    expect(result).toBe(80);
  });

  it('computes a weighted average across multiple scored tasks', () => {
    const heavy = taskFixture({ id: 'heavy', weight: 2 });
    const light = taskFixture({ id: 'light', weight: 1 });
    const result = service.calculateDay(date, [
      { task: heavy, occurrence: occurrenceFixture({ taskId: 'heavy', percentage: 100 }) },
      { task: light, occurrence: occurrenceFixture({ taskId: 'light', percentage: 40 }) },
    ]);
    expect(result).toBeCloseTo((100 * 2 + 40 * 1) / 3);
  });

  it('ignores a task that has ended before the given date', () => {
    const ended = taskFixture({ endsOn: toLocalDate('2026-03-01') });
    const result = service.calculateDay(date, [{ task: ended, occurrence: undefined }]);
    expect(result).toBeNull();
  });
});
