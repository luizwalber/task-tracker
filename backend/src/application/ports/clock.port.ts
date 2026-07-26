import { LocalDate } from '../../domain/local-date';

export const CLOCK_PORT = Symbol('ClockPort');

export interface ClockPort {
  today(): LocalDate;
}
