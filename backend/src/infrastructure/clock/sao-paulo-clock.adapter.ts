import { Injectable } from '@nestjs/common';
import { ClockPort } from '../../application/ports/clock.port';
import { LocalDate, toLocalDate } from '../../domain/local-date';

const APP_TIMEZONE = 'America/Sao_Paulo';

/**
 * The one place real wall-clock time turns into a LocalDate. Hardcoded to
 * America/Sao_Paulo, not per-user configurable — see the "Timezone and
 * persisted date" decision ticket.
 */
@Injectable()
export class SaoPauloClockAdapter implements ClockPort {
  today(): LocalDate {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: APP_TIMEZONE,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    return toLocalDate(formatter.format(new Date()));
  }
}
