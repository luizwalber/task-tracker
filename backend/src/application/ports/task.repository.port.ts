import { Task } from '../../domain/task/task.entity';

export const TASK_REPOSITORY = Symbol('TaskRepository');

export interface TaskRepositoryPort {
  save(task: Task): Promise<Task>;
  findAllForUser(userId: string): Promise<Task[]>;
  findOneForUser(userId: string, taskId: string): Promise<Task | null>;
}
