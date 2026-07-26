import { GetCalendarMonthUseCase } from './get-calendar-month.use-case';
import { CreateTaskUseCase } from '../task/create-task.use-case';
import { UpsertOccurrenceUseCase } from '../occurrence/upsert-occurrence.use-case';
import { InMemoryTaskRepository } from '../../../test/fixtures/in-memory-task.repository';
import { InMemoryTaskOccurrenceRepository } from '../../../test/fixtures/in-memory-task-occurrence.repository';
import { toLocalDate } from '../../domain/local-date';
import { ClockPort } from '../ports/clock.port';

class FixedClock implements ClockPort {
  constructor(private readonly date = toLocalDate('2026-03-15')) {}
  today() {
    return this.date;
  }
}

describe('GetCalendarMonthUseCase', () => {
  it('pads the month to full Sunday-starting weeks and reports recorded performance per day', async () => {
    const taskRepository = new InMemoryTaskRepository();
    const occurrenceRepository = new InMemoryTaskOccurrenceRepository();
    const task = await new CreateTaskUseCase(taskRepository).execute({
      userId: 'user-a',
      name: 'Gym',
      weight: 1,
      startsOn: toLocalDate('2026-03-01'),
    });
    await new UpsertOccurrenceUseCase(taskRepository, occurrenceRepository).execute({
      userId: 'user-a',
      taskId: task.id,
      date: toLocalDate('2026-03-10'),
      percentage: 70,
    });

    const useCase = new GetCalendarMonthUseCase(
      taskRepository,
      occurrenceRepository,
      new FixedClock(),
    );
    const result = await useCase.execute('user-a', 2026, 3);

    expect(result.serverToday).toBe('2026-03-15');
    // 2026-03-01 is a Sunday, so no leading padding is needed for this month.
    expect(result.days[0].date).toBe('2026-03-01');
    expect(result.days[result.days.length - 1].date >= '2026-03-31').toBe(true);

    const day10 = result.days.find((d) => d.date === '2026-03-10');
    expect(day10?.performance).toBe(70);
    expect(day10?.occurrences).toEqual([{ taskId: task.id, percentage: 70 }]);

    const day05 = result.days.find((d) => d.date === '2026-03-05');
    expect(day05?.performance).toBeNull();
    expect(day05?.occurrences).toEqual([]);
  });
});
