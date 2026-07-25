import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EnsureUserProjectionUseCase } from './application/users/ensure-user-projection.use-case';
import { FirebaseAdminModule } from './infrastructure/auth/firebase-admin.module';
import { entities } from './infrastructure/persistence/entities';
import { UserEntity } from './infrastructure/persistence/user.entity';
import { UserRepository } from './infrastructure/persistence/user.repository';
import { MeController } from './presentation/me.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        url: config.getOrThrow<string>('DATABASE_URL'),
        entities,
        synchronize: false,
      }),
      inject: [ConfigService],
    }),
    TypeOrmModule.forFeature([UserEntity]),
    FirebaseAdminModule,
  ],
  controllers: [MeController],
  providers: [UserRepository, EnsureUserProjectionUseCase],
})
export class AppModule {}
