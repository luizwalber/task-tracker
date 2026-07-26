import { DayPerformanceInput } from '../../domain/performance/performance-calculation.service';
import { Task } from '../../domain/task/task.entity';
import { TaskOccurrence } from '../../domain/occurrence/task-occurrence.entity';

/**
 * Pairs each of the user's tasks with its occurrence on a single date, if
 * any — the join `PerformanceCalculationService.calculateDay` needs. Shared
 * by UpsertOccurrenceUseCase and GetCalendarMonthUseCase so the pairing
 * logic doesn't drift between the two call sites.
 */
export function buildDayPerformanceInputs(
  tasks: Task[],
  occurrencesOnDate: TaskOccurrence[],
): DayPerformanceInput[] {
  return tasks.map((task) => ({
    task,
    occurrence: occurrencesOnDate.find((o) => o.taskId === task.id),
  }));
}
