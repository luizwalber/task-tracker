import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateTasksAndOccurrences1760000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS pgcrypto`);

    await queryRunner.query(`
      CREATE TABLE tasks (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id TEXT NOT NULL REFERENCES users(id),
        name TEXT NOT NULL,
        weight NUMERIC(3,1) NOT NULL DEFAULT 1 CHECK (weight BETWEEN 0.5 AND 2),
        starts_on DATE NOT NULL,
        ends_on DATE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
      CREATE INDEX idx_tasks_user ON tasks(user_id);
    `);

    await queryRunner.query(`
      CREATE TABLE task_occurrences (
        user_id TEXT NOT NULL REFERENCES users(id),
        task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        date DATE NOT NULL,
        percentage SMALLINT NOT NULL CHECK (percentage BETWEEN 0 AND 100 AND percentage % 10 = 0),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        PRIMARY KEY (user_id, task_id, date)
      );
      CREATE INDEX idx_occurrences_user_date ON task_occurrences(user_id, date);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE task_occurrences`);
    await queryRunner.query(`DROP TABLE tasks`);
  }
}
