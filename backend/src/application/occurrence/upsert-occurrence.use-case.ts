import { Inject, Injectable } from '@nestjs/common';
import { LocalDate } from '../../domain/local-date';
import { TaskOccurrence } from '../../domain/occurrence/task-occurrence.entity';
import { PerformanceCalculationService } from '../../domain/performance/performance-calculation.service';
import { TASK_REPOSITORY } from '../ports/task.repository.port';
import type { TaskRepositoryPort } from '../ports/task.repository.port';
import { TASK_OCCURRENCE_REPOSITORY } from '../ports/task-occurrence.repository.port';
import type { TaskOccurrenceRepositoryPort } from '../ports/task-occurrence.repository.port';
import { buildDayPerformanceInputs } from '../performance/build-day-performance-inputs';
import { TaskNotFoundError } from '../task/task-not-found.error';

export interface UpsertOccurrenceInput {
  userId: string;
  taskId: string;
  date: LocalDate;
  percentage: number;
}

export interface UpsertOccurrenceResult {
  occurrence: TaskOccurrence;
  dayPerformance: number | null;
}

@Injectable()
export class UpsertOccurrenceUseCase {
  private readonly performanceCalculationService = new PerformanceCalculationService();

  constructor(
    @Inject(TASK_REPOSITORY) private readonly taskRepository: TaskRepositoryPort,
    @Inject(TASK_OCCURRENCE_REPOSITORY)
    private readonly occurrenceRepository: TaskOccurrenceRepositoryPort,
  ) {}

  async execute(input: UpsertOccurrenceInput): Promise<UpsertOccurrenceResult> {
    const task = await this.taskRepository.findOneForUser(input.userId, input.taskId);
    if (!task) {
      throw new TaskNotFoundError(input.taskId);
    }

    const occurrence = await this.occurrenceRepository.upsert(
      new TaskOccurrence({
        userId: input.userId,
        taskId: input.taskId,
        date: input.date,
        percentage: input.percentage,
      }),
    );

    const tasks = await this.taskRepository.findAllForUser(input.userId);
    const occurrencesOnDate = await this.occurrenceRepository.findForUserInRange(
      input.userId,
      input.date,
      input.date,
    );

    const dayPerformance = this.performanceCalculationService.calculateDay(
      input.date,
      buildDayPerformanceInputs(tasks, occurrencesOnDate),
    );

    return { occurrence, dayPerformance };
  }
}
