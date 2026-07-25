import { Repository, SelectQueryBuilder } from 'typeorm';

export interface UserOwned {
  id: string;
  userId: string;
}

/**
 * Thrown by saveForUser when the target id belongs to another user. Presentation maps
 * this to a 404 (never a 403) — same "don't leak existence" rule as the read methods.
 */
export class OwnershipViolationError extends Error {
  constructor(id: string) {
    super(`Entity ${id} is not owned by the requesting user`);
  }
}

/**
 * Base for every repository that reads/writes user-owned data. There is no method here
 * that can build a query without a userId — that's the whole point: cross-user leaks are
 * structurally impossible to write, not just avoided by convention.
 */
export abstract class UserScopedRepository<T extends UserOwned> {
  protected constructor(protected readonly repo: Repository<T>) {}

  protected scoped(userId: string): SelectQueryBuilder<T> {
    return this.repo
      .createQueryBuilder('entity')
      .where('entity.userId = :userId', { userId });
  }

  findOneForUser(userId: string, id: string): Promise<T | null> {
    return this.scoped(userId).andWhere('entity.id = :id', { id }).getOne();
  }

  findAllForUser(userId: string): Promise<T[]> {
    return this.scoped(userId).getMany();
  }

  async saveForUser(userId: string, entity: Omit<T, 'userId'>): Promise<T> {
    const id = (entity as unknown as UserOwned).id;
    if (id) {
      await this.assertOwnership(userId, id);
    }
    return this.repo.save({ ...entity, userId } as unknown as T);
  }

  private async assertOwnership(userId: string, id: string): Promise<void> {
    const existing = await this.repo
      .createQueryBuilder('entity')
      .where('entity.id = :id', { id })
      .getOne();
    if (existing && (existing as unknown as UserOwned).userId !== userId) {
      throw new OwnershipViolationError(id);
    }
  }
}
