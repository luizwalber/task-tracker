import { Module, ValidationPipe } from '@nestjs/common';
import { APP_PIPE } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GetCalendarMonthUseCase } from './application/calendar/get-calendar-month.use-case';
import { UpsertOccurrenceUseCase } from './application/occurrence/upsert-occurrence.use-case';
import { CLOCK_PORT } from './application/ports/clock.port';
import { TASK_OCCURRENCE_REPOSITORY } from './application/ports/task-occurrence.repository.port';
import { TASK_REPOSITORY } from './application/ports/task.repository.port';
import { CreateTaskUseCase } from './application/task/create-task.use-case';
import { ListTasksUseCase } from './application/task/list-tasks.use-case';
import { UpdateTaskUseCase } from './application/task/update-task.use-case';
import { EnsureUserProjectionUseCase } from './application/users/ensure-user-projection.use-case';
import { SaoPauloClockAdapter } from './infrastructure/clock/sao-paulo-clock.adapter';
import { FirebaseAdminModule } from './infrastructure/auth/firebase-admin.module';
import { entities } from './infrastructure/persistence/entities';
import { TaskOccurrenceEntity } from './infrastructure/persistence/task-occurrence.entity';
import { TaskOccurrenceRepository } from './infrastructure/persistence/task-occurrence.repository';
import { TaskEntity } from './infrastructure/persistence/task.entity';
import { TaskRepository } from './infrastructure/persistence/task.repository';
import { UserEntity } from './infrastructure/persistence/user.entity';
import { UserRepository } from './infrastructure/persistence/user.repository';
import { CalendarController } from './presentation/calendar.controller';
import { MeController } from './presentation/me.controller';
import { OccurrenceController } from './presentation/occurrence.controller';
import { TaskController } from './presentation/task.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        url: config.getOrThrow<string>('DATABASE_URL'),
        entities,
        synchronize: false,
      }),
      inject: [ConfigService],
    }),
    TypeOrmModule.forFeature([UserEntity, TaskEntity, TaskOccurrenceEntity]),
    FirebaseAdminModule,
  ],
  controllers: [MeController, TaskController, CalendarController, OccurrenceController],
  providers: [
    { provide: APP_PIPE, useValue: new ValidationPipe({ whitelist: true, transform: true }) },
    UserRepository,
    EnsureUserProjectionUseCase,
    TaskRepository,
    TaskOccurrenceRepository,
    { provide: TASK_REPOSITORY, useExisting: TaskRepository },
    { provide: TASK_OCCURRENCE_REPOSITORY, useExisting: TaskOccurrenceRepository },
    { provide: CLOCK_PORT, useClass: SaoPauloClockAdapter },
    CreateTaskUseCase,
    ListTasksUseCase,
    UpdateTaskUseCase,
    UpsertOccurrenceUseCase,
    GetCalendarMonthUseCase,
  ],
})
export class AppModule {}
