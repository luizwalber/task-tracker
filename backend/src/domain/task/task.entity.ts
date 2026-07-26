import { LocalDate } from '../local-date';

export interface TaskProps {
  id: string;
  userId: string;
  name: string;
  weight: number;
  startsOn: LocalDate;
  endsOn?: LocalDate;
}

/**
 * Recurrence is fixed to "every day" for this slice — full RecurrenceRule
 * (WEEKLY_DAYS, MONTHLY_DAY, INTERVAL, PAUSED, versioning) is a later ticket.
 */
export class Task {
  readonly id: string;
  readonly userId: string;
  readonly name: string;
  readonly weight: number;
  readonly startsOn: LocalDate;
  readonly endsOn?: LocalDate;

  constructor(props: TaskProps) {
    if (props.weight < 0.5 || props.weight > 2) {
      throw new Error('Task weight must be between 0.5 and 2');
    }
    if (props.endsOn && props.endsOn < props.startsOn) {
      throw new Error('Task endsOn cannot be before startsOn');
    }
    this.id = props.id;
    this.userId = props.userId;
    this.name = props.name;
    this.weight = props.weight;
    this.startsOn = props.startsOn;
    this.endsOn = props.endsOn;
  }

  occursOn(date: LocalDate): boolean {
    if (date < this.startsOn) return false;
    if (this.endsOn && date > this.endsOn) return false;
    return true;
  }
}
