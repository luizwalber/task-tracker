import { LocalDate } from '../../src/domain/local-date';
import { TaskOccurrence } from '../../src/domain/occurrence/task-occurrence.entity';
import { TaskOccurrenceRepositoryPort } from '../../src/application/ports/task-occurrence.repository.port';

export class InMemoryTaskOccurrenceRepository implements TaskOccurrenceRepositoryPort {
  occurrences: TaskOccurrence[] = [];

  async upsert(occurrence: TaskOccurrence): Promise<TaskOccurrence> {
    this.occurrences = this.occurrences.filter(
      (o) =>
        !(
          o.userId === occurrence.userId &&
          o.taskId === occurrence.taskId &&
          o.date === occurrence.date
        ),
    );
    this.occurrences.push(occurrence);
    return occurrence;
  }

  async findForUserInRange(
    userId: string,
    from: LocalDate,
    to: LocalDate,
  ): Promise<TaskOccurrence[]> {
    return this.occurrences.filter(
      (o) => o.userId === userId && o.date >= from && o.date <= to,
    );
  }
}
