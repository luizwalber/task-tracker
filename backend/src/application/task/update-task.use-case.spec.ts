import { UpdateTaskUseCase } from './update-task.use-case';
import { CreateTaskUseCase } from './create-task.use-case';
import { InMemoryTaskRepository } from '../../../test/fixtures/in-memory-task.repository';
import { toLocalDate } from '../../domain/local-date';
import { TaskNotFoundError } from './task-not-found.error';

describe('UpdateTaskUseCase', () => {
  it('updates only the provided fields, keeping id and userId', async () => {
    const repository = new InMemoryTaskRepository();
    const created = await new CreateTaskUseCase(repository).execute({
      userId: 'user-a',
      name: 'Gym',
      weight: 1,
      startsOn: toLocalDate('2026-03-01'),
    });

    const updated = await new UpdateTaskUseCase(repository).execute({
      userId: 'user-a',
      taskId: created.id,
      name: 'Gym 5x',
      weight: 1.5,
    });

    expect(updated.id).toBe(created.id);
    expect(updated.userId).toBe('user-a');
    expect(updated.name).toBe('Gym 5x');
    expect(updated.weight).toBe(1.5);
    expect(updated.startsOn).toBe(created.startsOn);
  });

  it('rejects updating a task that does not belong to the requesting user', async () => {
    const repository = new InMemoryTaskRepository();
    const created = await new CreateTaskUseCase(repository).execute({
      userId: 'user-a',
      name: 'Gym',
      weight: 1,
      startsOn: toLocalDate('2026-03-01'),
    });

    await expect(
      new UpdateTaskUseCase(repository).execute({
        userId: 'user-b',
        taskId: created.id,
        name: 'Hijacked',
      }),
    ).rejects.toThrow(TaskNotFoundError);
  });
});
