import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { TaskRepositoryPort } from '../../application/ports/task.repository.port';
import { Task } from '../../domain/task/task.entity';
import { toLocalDate } from '../../domain/local-date';
import { TaskEntity } from './task.entity';
import { UserScopedRepository } from './user-scoped.repository';

/**
 * Thin concrete subclass with no overrides — exists only to satisfy
 * UserScopedRepository's protected constructor so TaskRepository can compose
 * it instead of inheriting method names it needs to re-type from
 * TaskEntity to the domain Task.
 */
class TaskEntityScopedRepository extends UserScopedRepository<TaskEntity> {
  constructor(repo: Repository<TaskEntity>) {
    super(repo);
  }
}

@Injectable()
export class TaskRepository implements TaskRepositoryPort {
  private readonly scoped: TaskEntityScopedRepository;

  constructor(@InjectRepository(TaskEntity) repo: Repository<TaskEntity>) {
    this.scoped = new TaskEntityScopedRepository(repo);
  }

  async save(task: Task): Promise<Task> {
    const saved = await this.scoped.saveForUser(task.userId, {
      id: task.id,
      name: task.name,
      weight: task.weight,
      startsOn: task.startsOn,
      endsOn: task.endsOn ?? null,
    });
    return this.toDomain(saved);
  }

  async findAllForUser(userId: string): Promise<Task[]> {
    const entities = await this.scoped.findAllForUser(userId);
    return entities.map((e) => this.toDomain(e));
  }

  async findOneForUser(userId: string, taskId: string): Promise<Task | null> {
    const entity = await this.scoped.findOneForUser(userId, taskId);
    return entity ? this.toDomain(entity) : null;
  }

  private toDomain(entity: TaskEntity): Task {
    return new Task({
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      weight: entity.weight,
      startsOn: toLocalDate(entity.startsOn),
      endsOn: entity.endsOn ? toLocalDate(entity.endsOn) : undefined,
    });
  }
}
