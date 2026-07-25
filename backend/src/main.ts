import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import dataSource from './infrastructure/persistence/data-source';

async function runPendingMigrations(): Promise<void> {
  await dataSource.initialize();
  await dataSource.runMigrations();
  await dataSource.destroy();
}

async function bootstrap() {
  await runPendingMigrations(); // fail fast: never boot the API against a stale schema
  const app = await NestFactory.create(AppModule);
  app.enableCors(); // Flutter Web runs on its own dev-server origin, separate from the API's
  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
