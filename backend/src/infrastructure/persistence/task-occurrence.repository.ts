import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, Repository } from 'typeorm';
import { TaskOccurrenceRepositoryPort } from '../../application/ports/task-occurrence.repository.port';
import { LocalDate, toLocalDate } from '../../domain/local-date';
import { TaskOccurrence } from '../../domain/occurrence/task-occurrence.entity';
import { TaskOccurrenceEntity } from './task-occurrence.entity';

/**
 * Composite natural key (userId + taskId + date), not a UserScopedRepository
 * subclass — that base class is built around a single synthetic `id`. Task
 * ownership of `taskId` is verified one layer up, by the use case, via
 * TaskRepository.findOneForUser before this repository is ever called.
 */
@Injectable()
export class TaskOccurrenceRepository implements TaskOccurrenceRepositoryPort {
  constructor(
    @InjectRepository(TaskOccurrenceEntity)
    private readonly repo: Repository<TaskOccurrenceEntity>,
  ) {}

  async upsert(occurrence: TaskOccurrence): Promise<TaskOccurrence> {
    // A single atomic `INSERT ... ON CONFLICT (user_id, task_id, date) DO
    // UPDATE`, not a check-then-insert/update — safe under concurrent
    // upserts to the same natural key.
    await this.repo.upsert(
      {
        userId: occurrence.userId,
        taskId: occurrence.taskId,
        date: occurrence.date,
        percentage: occurrence.percentage,
      },
      ['userId', 'taskId', 'date'],
    );
    const saved = await this.repo.findOneByOrFail({
      userId: occurrence.userId,
      taskId: occurrence.taskId,
      date: occurrence.date,
    });
    return this.toDomain(saved);
  }

  async findForUserInRange(
    userId: string,
    from: LocalDate,
    to: LocalDate,
  ): Promise<TaskOccurrence[]> {
    const entities = await this.repo.find({
      where: { userId, date: Between(from, to) },
    });
    return entities.map((e) => this.toDomain(e));
  }

  private toDomain(entity: TaskOccurrenceEntity): TaskOccurrence {
    return new TaskOccurrence({
      userId: entity.userId,
      taskId: entity.taskId,
      date: toLocalDate(entity.date),
      percentage: entity.percentage,
    });
  }
}
