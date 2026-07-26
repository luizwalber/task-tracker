import { Controller, Get, Param, ParseIntPipe, UseGuards } from '@nestjs/common';
import { GetCalendarMonthUseCase } from '../application/calendar/get-calendar-month.use-case';
import type { AuthenticatedUser } from '../domain/auth/authenticated-user';
import { FirebaseAuthGuard } from '../infrastructure/auth/firebase-auth.guard';
import { CurrentUser } from './current-user.decorator';

@UseGuards(FirebaseAuthGuard)
@Controller('calendar')
export class CalendarController {
  constructor(private readonly getCalendarMonth: GetCalendarMonthUseCase) {}

  @Get(':year/:month')
  async getMonth(
    @CurrentUser() user: AuthenticatedUser,
    @Param('year', ParseIntPipe) year: number,
    @Param('month', ParseIntPipe) month: number,
  ) {
    return this.getCalendarMonth.execute(user.uid, year, month);
  }
}
