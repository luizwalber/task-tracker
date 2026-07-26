import { Body, Controller, NotFoundException, Param, Put, UseGuards } from '@nestjs/common';
import { UpsertOccurrenceUseCase } from '../application/occurrence/upsert-occurrence.use-case';
import { TaskNotFoundError } from '../application/task/task-not-found.error';
import { EnsureUserProjectionUseCase } from '../application/users/ensure-user-projection.use-case';
import type { AuthenticatedUser } from '../domain/auth/authenticated-user';
import { toLocalDate } from '../domain/local-date';
import { FirebaseAuthGuard } from '../infrastructure/auth/firebase-auth.guard';
import { CurrentUser } from './current-user.decorator';
import { UpsertOccurrenceDto } from './dto/upsert-occurrence.dto';

@UseGuards(FirebaseAuthGuard)
@Controller('occurrences')
export class OccurrenceController {
  constructor(
    private readonly upsertOccurrence: UpsertOccurrenceUseCase,
    private readonly ensureUserProjection: EnsureUserProjectionUseCase,
  ) {}

  @Put(':taskId/:date')
  async upsert(
    @CurrentUser() user: AuthenticatedUser,
    @Param('taskId') taskId: string,
    @Param('date') date: string,
    @Body() dto: UpsertOccurrenceDto,
  ) {
    await this.ensureUserProjection.execute({ uid: user.uid });
    try {
      const { occurrence, dayPerformance } = await this.upsertOccurrence.execute({
        userId: user.uid,
        taskId,
        date: toLocalDate(date),
        percentage: dto.percentage,
      });
      return {
        occurrence: {
          taskId: occurrence.taskId,
          date: occurrence.date,
          percentage: occurrence.percentage,
        },
        dayPerformance,
      };
    } catch (error) {
      if (error instanceof TaskNotFoundError) {
        throw new NotFoundException();
      }
      throw error;
    }
  }
}
