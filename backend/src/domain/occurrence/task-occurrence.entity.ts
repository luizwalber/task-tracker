import { LocalDate } from '../local-date';

export interface TaskOccurrenceProps {
  userId: string;
  taskId: string;
  date: LocalDate;
  percentage: number;
}

/**
 * Only exists as a row once something was recorded — never pre-materialized
 * for every expected day. REST state and photo/weight fields belong to
 * later tickets (rest quota, photos, body-weight tracking).
 */
export class TaskOccurrence {
  readonly userId: string;
  readonly taskId: string;
  readonly date: LocalDate;
  readonly percentage: number;

  constructor(props: TaskOccurrenceProps) {
    if (props.percentage < 0 || props.percentage > 100 || props.percentage % 10 !== 0) {
      throw new Error('Occurrence percentage must be a multiple of 10 between 0 and 100');
    }
    this.userId = props.userId;
    this.taskId = props.taskId;
    this.date = props.date;
    this.percentage = props.percentage;
  }
}
