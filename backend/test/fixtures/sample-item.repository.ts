import { Repository } from 'typeorm';
import { UserScopedRepository } from '../../src/infrastructure/persistence/user-scoped.repository';
import { SampleItemEntity } from './sample-item.entity';

export class SampleItemRepository extends UserScopedRepository<SampleItemEntity> {
  constructor(repo: Repository<SampleItemEntity>) {
    super(repo);
  }
}
