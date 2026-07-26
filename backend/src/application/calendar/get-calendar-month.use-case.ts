import { Inject, Injectable } from '@nestjs/common';
import {
  addDays,
  firstDayOfMonth,
  lastDayOfMonth,
  LocalDate,
  startOfWeekSunday,
} from '../../domain/local-date';
import { PerformanceCalculationService } from '../../domain/performance/performance-calculation.service';
import { CLOCK_PORT } from '../ports/clock.port';
import type { ClockPort } from '../ports/clock.port';
import { TASK_REPOSITORY } from '../ports/task.repository.port';
import type { TaskRepositoryPort } from '../ports/task.repository.port';
import { TASK_OCCURRENCE_REPOSITORY } from '../ports/task-occurrence.repository.port';
import type { TaskOccurrenceRepositoryPort } from '../ports/task-occurrence.repository.port';
import { buildDayPerformanceInputs } from '../performance/build-day-performance-inputs';

export interface CalendarDayDto {
  date: LocalDate;
  performance: number | null;
  occurrences: { taskId: string; percentage: number }[];
}

export interface GetCalendarMonthResult {
  serverToday: LocalDate;
  days: CalendarDayDto[];
}

@Injectable()
export class GetCalendarMonthUseCase {
  private readonly performanceCalculationService = new PerformanceCalculationService();

  constructor(
    @Inject(TASK_REPOSITORY) private readonly taskRepository: TaskRepositoryPort,
    @Inject(TASK_OCCURRENCE_REPOSITORY)
    private readonly occurrenceRepository: TaskOccurrenceRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
  ) {}

  async execute(userId: string, year: number, month: number): Promise<GetCalendarMonthResult> {
    const rangeStart = startOfWeekSunday(firstDayOfMonth(year, month));
    const monthEnd = lastDayOfMonth(year, month);
    const rangeEnd = this.endOfWeekSaturday(monthEnd);

    const [tasks, occurrences] = await Promise.all([
      this.taskRepository.findAllForUser(userId),
      this.occurrenceRepository.findForUserInRange(userId, rangeStart, rangeEnd),
    ]);

    const days: CalendarDayDto[] = [];
    for (let date = rangeStart; date <= rangeEnd; date = addDays(date, 1)) {
      const occurrencesOnDate = occurrences.filter((o) => o.date === date);
      const performance = this.performanceCalculationService.calculateDay(
        date,
        buildDayPerformanceInputs(tasks, occurrencesOnDate),
      );
      days.push({
        date,
        performance,
        occurrences: occurrencesOnDate.map((o) => ({
          taskId: o.taskId,
          percentage: o.percentage,
        })),
      });
    }

    return { serverToday: this.clock.today(), days };
  }

  private endOfWeekSaturday(date: LocalDate): LocalDate {
    return addDays(startOfWeekSunday(date), 6);
  }
}
