import { Inject, Injectable } from '@nestjs/common';
import { Task } from '../../domain/task/task.entity';
import { TASK_REPOSITORY } from '../ports/task.repository.port';
import type { TaskRepositoryPort } from '../ports/task.repository.port';

@Injectable()
export class ListTasksUseCase {
  constructor(
    @Inject(TASK_REPOSITORY) private readonly taskRepository: TaskRepositoryPort,
  ) {}

  execute(userId: string): Promise<Task[]> {
    return this.taskRepository.findAllForUser(userId);
  }
}
