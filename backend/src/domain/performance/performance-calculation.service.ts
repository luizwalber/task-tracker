import { LocalDate } from '../local-date';
import { Task } from '../task/task.entity';
import { TaskOccurrence } from '../occurrence/task-occurrence.entity';

export interface DayPerformanceInput {
  task: Task;
  occurrence?: TaskOccurrence; // undefined = not yet filled in
}

/**
 * Isolated, trocable business rule: weighted average of every expected task's
 * score for a day, excluding tasks that haven't been filled in yet (unfilled
 * is not the same as 0%). Rest-day quota scoring is a later ticket — every
 * occurrence in this slice carries a plain percentage.
 */
export class PerformanceCalculationService {
  calculateDay(date: LocalDate, inputs: DayPerformanceInput[]): number | null {
    const scored = inputs
      .filter((input) => input.task.occursOn(date))
      .map((input) => this.scoreOne(input))
      .filter((s): s is { weight: number; value: number } => s !== null);

    if (scored.length === 0) return null;

    const totalWeight = scored.reduce((sum, s) => sum + s.weight, 0);
    return scored.reduce((sum, s) => sum + s.value * s.weight, 0) / totalWeight;
  }

  private scoreOne(input: DayPerformanceInput): { weight: number; value: number } | null {
    if (!input.occurrence) return null; // unfilled, excluded from the denominator
    return { weight: input.task.weight, value: input.occurrence.percentage };
  }
}
