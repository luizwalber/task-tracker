import { Task } from '../../src/domain/task/task.entity';
import { TaskRepositoryPort } from '../../src/application/ports/task.repository.port';

export class InMemoryTaskRepository implements TaskRepositoryPort {
  tasks: Task[] = [];

  async save(task: Task): Promise<Task> {
    this.tasks = this.tasks.filter((t) => t.id !== task.id);
    this.tasks.push(task);
    return task;
  }

  async findAllForUser(userId: string): Promise<Task[]> {
    return this.tasks.filter((t) => t.userId === userId);
  }

  async findOneForUser(userId: string, taskId: string): Promise<Task | null> {
    return this.tasks.find((t) => t.userId === userId && t.id === taskId) ?? null;
  }
}
