import { UpsertOccurrenceUseCase } from './upsert-occurrence.use-case';
import { CreateTaskUseCase } from '../task/create-task.use-case';
import { InMemoryTaskRepository } from '../../../test/fixtures/in-memory-task.repository';
import { InMemoryTaskOccurrenceRepository } from '../../../test/fixtures/in-memory-task-occurrence.repository';
import { toLocalDate } from '../../domain/local-date';
import { TaskNotFoundError } from '../task/task-not-found.error';

describe('UpsertOccurrenceUseCase', () => {
  it('is idempotent by userId + taskId + date and returns the recomputed day performance', async () => {
    const taskRepository = new InMemoryTaskRepository();
    const occurrenceRepository = new InMemoryTaskOccurrenceRepository();
    const task = await new CreateTaskUseCase(taskRepository).execute({
      userId: 'user-a',
      name: 'Gym',
      weight: 1,
      startsOn: toLocalDate('2026-03-01'),
    });
    const useCase = new UpsertOccurrenceUseCase(taskRepository, occurrenceRepository);
    const date = toLocalDate('2026-03-10');

    const first = await useCase.execute({ userId: 'user-a', taskId: task.id, date, percentage: 50 });
    expect(first.dayPerformance).toBe(50);
    expect(occurrenceRepository.occurrences).toHaveLength(1);

    const second = await useCase.execute({ userId: 'user-a', taskId: task.id, date, percentage: 80 });
    expect(second.dayPerformance).toBe(80);
    expect(occurrenceRepository.occurrences).toHaveLength(1); // upsert, not a second row
  });

  it('rejects an occurrence for a task that does not belong to the requesting user', async () => {
    const taskRepository = new InMemoryTaskRepository();
    const occurrenceRepository = new InMemoryTaskOccurrenceRepository();
    const task = await new CreateTaskUseCase(taskRepository).execute({
      userId: 'user-a',
      name: 'Gym',
      weight: 1,
      startsOn: toLocalDate('2026-03-01'),
    });
    const useCase = new UpsertOccurrenceUseCase(taskRepository, occurrenceRepository);

    await expect(
      useCase.execute({
        userId: 'user-b',
        taskId: task.id,
        date: toLocalDate('2026-03-10'),
        percentage: 50,
      }),
    ).rejects.toThrow(TaskNotFoundError);
  });
});
