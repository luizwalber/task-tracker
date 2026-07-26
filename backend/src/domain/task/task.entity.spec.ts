import { Task, TaskProps } from './task.entity';
import { toLocalDate } from '../local-date';

function taskFixture(overrides: Partial<TaskProps> = {}) {
  return new Task({
    id: 't1',
    userId: 'user-a',
    name: 'Gym',
    weight: 1,
    startsOn: toLocalDate('2026-03-01'),
    ...overrides,
  });
}

describe('Task', () => {
  it('rejects a weight outside 0.5-2', () => {
    expect(() => taskFixture({ weight: 0.4 })).toThrow();
    expect(() => taskFixture({ weight: 2.1 })).toThrow();
  });

  it('rejects an endsOn before startsOn', () => {
    expect(() =>
      taskFixture({ startsOn: toLocalDate('2026-03-10'), endsOn: toLocalDate('2026-03-01') }),
    ).toThrow();
  });

  it('occurs every day from startsOn onward when there is no endsOn', () => {
    const task = taskFixture({ startsOn: toLocalDate('2026-03-05') });
    expect(task.occursOn(toLocalDate('2026-03-04'))).toBe(false);
    expect(task.occursOn(toLocalDate('2026-03-05'))).toBe(true);
    expect(task.occursOn(toLocalDate('2026-06-01'))).toBe(true);
  });

  it('stops occurring after endsOn', () => {
    const task = taskFixture({
      startsOn: toLocalDate('2026-03-05'),
      endsOn: toLocalDate('2026-03-10'),
    });
    expect(task.occursOn(toLocalDate('2026-03-10'))).toBe(true);
    expect(task.occursOn(toLocalDate('2026-03-11'))).toBe(false);
  });
});
