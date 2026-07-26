import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Task } from '../../domain/task/task.entity';
import { LocalDate } from '../../domain/local-date';
import { TASK_REPOSITORY } from '../ports/task.repository.port';
import type { TaskRepositoryPort } from '../ports/task.repository.port';

export interface CreateTaskInput {
  userId: string;
  name: string;
  weight: number;
  startsOn: LocalDate;
  endsOn?: LocalDate;
}

@Injectable()
export class CreateTaskUseCase {
  constructor(
    @Inject(TASK_REPOSITORY) private readonly taskRepository: TaskRepositoryPort,
  ) {}

  execute(input: CreateTaskInput): Promise<Task> {
    const task = new Task({
      id: randomUUID(),
      userId: input.userId,
      name: input.name,
      weight: input.weight,
      startsOn: input.startsOn,
      endsOn: input.endsOn,
    });
    return this.taskRepository.save(task);
  }
}
