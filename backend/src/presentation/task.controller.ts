import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  UnprocessableEntityException,
  UseGuards,
} from '@nestjs/common';
import { CreateTaskUseCase } from '../application/task/create-task.use-case';
import { ListTasksUseCase } from '../application/task/list-tasks.use-case';
import { UpdateTaskUseCase } from '../application/task/update-task.use-case';
import { TaskNotFoundError } from '../application/task/task-not-found.error';
import { EnsureUserProjectionUseCase } from '../application/users/ensure-user-projection.use-case';
import { toLocalDate } from '../domain/local-date';
import { Task } from '../domain/task/task.entity';
import { FirebaseAuthGuard } from '../infrastructure/auth/firebase-auth.guard';
import type { AuthenticatedUser } from '../domain/auth/authenticated-user';
import { CurrentUser } from './current-user.decorator';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';

function toTaskResponse(task: Task) {
  return {
    id: task.id,
    name: task.name,
    weight: task.weight,
    startsOn: task.startsOn,
    endsOn: task.endsOn ?? null,
  };
}

@UseGuards(FirebaseAuthGuard)
@Controller('tasks')
export class TaskController {
  constructor(
    private readonly createTask: CreateTaskUseCase,
    private readonly listTasks: ListTasksUseCase,
    private readonly updateTask: UpdateTaskUseCase,
    private readonly ensureUserProjection: EnsureUserProjectionUseCase,
  ) {}

  @Get()
  async list(@CurrentUser() user: AuthenticatedUser) {
    const tasks = await this.listTasks.execute(user.uid);
    return tasks.map(toTaskResponse);
  }

  @Post()
  async create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateTaskDto) {
    await this.ensureUserProjection.execute({ uid: user.uid });
    try {
      const task = await this.createTask.execute({
        userId: user.uid,
        name: dto.name,
        weight: dto.weight,
        startsOn: toLocalDate(dto.startsOn),
        endsOn: dto.endsOn ? toLocalDate(dto.endsOn) : undefined,
      });
      return toTaskResponse(task);
    } catch (error) {
      if (error instanceof Error) {
        throw new UnprocessableEntityException(error.message);
      }
      throw error;
    }
  }

  @Patch(':taskId')
  async update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('taskId') taskId: string,
    @Body() dto: UpdateTaskDto,
  ) {
    try {
      const task = await this.updateTask.execute({
        userId: user.uid,
        taskId,
        name: dto.name,
        weight: dto.weight,
        startsOn: dto.startsOn ? toLocalDate(dto.startsOn) : undefined,
        endsOn: dto.endsOn ? toLocalDate(dto.endsOn) : undefined,
      });
      return toTaskResponse(task);
    } catch (error) {
      if (error instanceof TaskNotFoundError) {
        throw new NotFoundException();
      }
      if (error instanceof Error) {
        throw new UnprocessableEntityException(error.message);
      }
      throw error;
    }
  }
}
