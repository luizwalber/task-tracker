import { CreateTaskUseCase } from './create-task.use-case';
import { InMemoryTaskRepository } from '../../../test/fixtures/in-memory-task.repository';
import { toLocalDate } from '../../domain/local-date';

describe('CreateTaskUseCase', () => {
  it('persists a new task owned by the requesting user', async () => {
    const repository = new InMemoryTaskRepository();
    const useCase = new CreateTaskUseCase(repository);

    const task = await useCase.execute({
      userId: 'user-a',
      name: 'Gym',
      weight: 1,
      startsOn: toLocalDate('2026-03-01'),
    });

    expect(task.id).toBeTruthy();
    expect(repository.tasks).toHaveLength(1);
    expect(repository.tasks[0].userId).toBe('user-a');
  });
});
