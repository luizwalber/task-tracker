import { LocalDate } from '../../domain/local-date';
import { TaskOccurrence } from '../../domain/occurrence/task-occurrence.entity';

export const TASK_OCCURRENCE_REPOSITORY = Symbol('TaskOccurrenceRepository');

export interface TaskOccurrenceRepositoryPort {
  upsert(occurrence: TaskOccurrence): Promise<TaskOccurrence>;
  findForUserInRange(
    userId: string,
    from: LocalDate,
    to: LocalDate,
  ): Promise<TaskOccurrence[]>;
}
