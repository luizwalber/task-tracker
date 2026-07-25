import {
  PostgreSqlContainer,
  StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import { DataSource } from 'typeorm';
import { SampleItemEntity } from '../fixtures/sample-item.entity';
import { SampleItemRepository } from '../fixtures/sample-item.repository';
import { itIsolatesByUser } from '../support/isolation-contract';

describe('UserScopedRepository — cross-user isolation contract', () => {
  jest.setTimeout(120_000);

  let container: StartedPostgreSqlContainer;
  let dataSource: DataSource;
  let repository: SampleItemRepository;

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgres:16-alpine').start();
    dataSource = new DataSource({
      type: 'postgres',
      url: container.getConnectionUri(),
      entities: [SampleItemEntity],
      synchronize: true, // fine for this ephemeral fixture-only test database
    });
    await dataSource.initialize();
    repository = new SampleItemRepository(
      dataSource.getRepository(SampleItemEntity),
    );
  });

  afterAll(async () => {
    await dataSource?.destroy();
    await container?.stop();
  });

  afterEach(async () => {
    await dataSource.getRepository(SampleItemEntity).clear();
  });

  itIsolatesByUser(
    () => repository,
    (userId) =>
      repository.saveForUser(userId, { label: 'owned by ' + userId } as Omit<
        SampleItemEntity,
        'userId'
      >),
  );
});
