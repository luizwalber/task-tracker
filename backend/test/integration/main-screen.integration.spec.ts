import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import {
  PostgreSqlContainer,
  StartedPostgreSqlContainer,
} from '@testcontainers/postgresql';
import type { Auth } from 'firebase-admin/auth';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { entities } from '../../src/infrastructure/persistence/entities';
import { CreateUsers1753000000000 } from '../../src/infrastructure/persistence/migrations/1753000000000-CreateUsers';
import { CreateTasksAndOccurrences1760000000000 } from '../../src/infrastructure/persistence/migrations/1760000000000-CreateTasksAndOccurrences';
import { FIREBASE_AUTH } from '../../src/infrastructure/auth/firebase-auth.token';
import { AppModule } from '../../src/app.module';

// See me.integration.spec.ts for why firebase-admin/auth is mocked at the module level.
jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));

describe('Main screen end-to-end — tasks, calendar, occurrence upsert', () => {
  jest.setTimeout(120_000);

  let container: StartedPostgreSqlContainer;
  let app: INestApplication;
  const fakeAuth: Pick<Auth, 'verifyIdToken'> = { verifyIdToken: jest.fn() };

  function authAs(uid: string) {
    (fakeAuth.verifyIdToken as jest.Mock).mockResolvedValueOnce({ uid });
    return { Authorization: `Bearer token-for-${uid}` };
  }

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgres:16-alpine').start();
    process.env.DATABASE_URL = container.getConnectionUri();

    const migrator = new DataSource({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      entities,
      migrations: [CreateUsers1753000000000, CreateTasksAndOccurrences1760000000000],
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

  it('creates a task, drags the slider, and gets back the recomputed day performance without a month refetch', async () => {
    const owner = authAs('user-main-a');
    const createResponse = await request(app.getHttpServer())
      .post('/tasks')
      .set(owner)
      .send({ name: 'Gym', weight: 1, startsOn: '2026-03-01' })
      .expect(201);

    const taskId = createResponse.body.id;

    await request(app.getHttpServer())
      .get('/tasks')
      .set(authAs('user-main-a'))
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveLength(1);
        expect(res.body[0].id).toBe(taskId);
      });

    const upsertResponse = await request(app.getHttpServer())
      .put(`/occurrences/${taskId}/2026-03-10`)
      .set(authAs('user-main-a'))
      .send({ percentage: 70 })
      .expect(200);

    expect(upsertResponse.body).toEqual({
      occurrence: { taskId, date: '2026-03-10', percentage: 70 },
      dayPerformance: 70,
    });

    // idempotent upsert — same natural key, no duplicate row, updated value comes back
    const secondUpsert = await request(app.getHttpServer())
      .put(`/occurrences/${taskId}/2026-03-10`)
      .set(authAs('user-main-a'))
      .send({ percentage: 100 })
      .expect(200);
    expect(secondUpsert.body.dayPerformance).toBe(100);

    const calendarResponse = await request(app.getHttpServer())
      .get('/calendar/2026/3')
      .set(authAs('user-main-a'))
      .expect(200);

    const day10 = calendarResponse.body.days.find((d: { date: string }) => d.date === '2026-03-10');
    expect(day10.performance).toBe(100);
    expect(day10.occurrences).toEqual([{ taskId, percentage: 100 }]);
  });

  it("never leaks one user's task to another (404, not 403)", async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/tasks')
      .set(authAs('user-owner'))
      .send({ name: 'Diet', weight: 1, startsOn: '2026-03-01' })
      .expect(201);

    const taskId = createResponse.body.id;

    await request(app.getHttpServer())
      .put(`/occurrences/${taskId}/2026-03-10`)
      .set(authAs('user-intruder'))
      .send({ percentage: 50 })
      .expect(404);

    await request(app.getHttpServer())
      .patch(`/tasks/${taskId}`)
      .set(authAs('user-intruder'))
      .send({ name: 'Hijacked' })
      .expect(404);
  });

  it('rejects a percentage that is not a multiple of 10', async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/tasks')
      .set(authAs('user-validation'))
      .send({ name: 'Reading', weight: 1, startsOn: '2026-03-01' })
      .expect(201);

    await request(app.getHttpServer())
      .put(`/occurrences/${createResponse.body.id}/2026-03-10`)
      .set(authAs('user-validation'))
      .send({ percentage: 55 })
      .expect(400);
  });
});
