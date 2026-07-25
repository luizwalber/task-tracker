import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import {
  PostgreSqlContainer,
  StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import type { Auth } from 'firebase-admin/auth';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { CreateUsers1753000000000 } from '../../src/infrastructure/persistence/migrations/1753000000000-CreateUsers';
import { UserEntity } from '../../src/infrastructure/persistence/user.entity';
import { FIREBASE_AUTH } from '../../src/infrastructure/auth/firebase-auth.token';
import { AppModule } from '../../src/app.module';

// The real firebase-admin/auth module transitively pulls in `jose` (ESM-only), which
// Jest's CJS transform can't parse. We override the FIREBASE_AUTH provider below anyway,
// so the real implementation is never needed — just its shape.
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));

describe('GET /me — end-to-end through guard, use case and repository', () => {
  jest.setTimeout(120_000);

  let container: StartedPostgreSqlContainer;
  let app: INestApplication;
  const fakeAuth: Pick<Auth, 'verifyIdToken'> = { verifyIdToken: jest.fn() };

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgres:16-alpine').start();
    process.env.DATABASE_URL = container.getConnectionUri();

    const migrator = new DataSource({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      entities: [UserEntity],
      migrations: [CreateUsers1753000000000],
    });
    await migrator.initialize();
    await migrator.runMigrations();
    await migrator.destroy();

    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(FIREBASE_AUTH)
      .useValue(fakeAuth)
      .compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app?.close();
    await container?.stop();
  });

  it('rejects a request with no token', async () => {
    await request(app.getHttpServer()).get('/me').expect(401);
  });

  it('returns the user projection for a valid token, creating it on first sight', async () => {
    (fakeAuth.verifyIdToken as jest.Mock).mockResolvedValueOnce({
      uid: 'firebase-user-1',
    });

    const response = await request(app.getHttpServer())
      .get('/me')
      .set('Authorization', 'Bearer valid-token')
      .expect(200);

    expect(response.body).toMatchObject({ id: 'firebase-user-1' });
  });
});
