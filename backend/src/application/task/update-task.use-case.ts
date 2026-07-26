import { Inject, Injectable } from '@nestjs/common';
import { Task } from '../../domain/task/task.entity';
import { LocalDate } from '../../domain/local-date';
import { TASK_REPOSITORY } from '../ports/task.repository.port';
import type { TaskRepositoryPort } from '../ports/task.repository.port';
import { TaskNotFoundError } from './task-not-found.error';

export interface UpdateTaskInput {
  userId: string;
  taskId: string;
  name?: string;
  weight?: number;
  startsOn?: LocalDate;
  endsOn?: LocalDate;
}

@Injectable()
export class UpdateTaskUseCase {
  constructor(
    @Inject(TASK_REPOSITORY) private readonly taskRepository: TaskRepositoryPort,
  ) {}

  async execute(input: UpdateTaskInput): Promise<Task> {
    const existing = await this.taskRepository.findOneForUser(input.userId, input.taskId);
    if (!existing) {
      throw new TaskNotFoundError(input.taskId);
    }

    const updated = new Task({
      id: existing.id,
      userId: existing.userId,
      name: input.name ?? existing.name,
      weight: input.weight ?? existing.weight,
      startsOn: input.startsOn ?? existing.startsOn,
      endsOn: input.endsOn ?? existing.endsOn,
    });

    return this.taskRepository.save(updated);
  }
}
