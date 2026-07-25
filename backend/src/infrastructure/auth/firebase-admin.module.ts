import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { cert, initializeApp } from 'firebase-admin/app';
import type { Auth } from 'firebase-admin/auth';
import { getAuth } from 'firebase-admin/auth';
import { FIREBASE_AUTH } from './firebase-auth.token';

@Module({
  providers: [
    {
      provide: FIREBASE_AUTH,
      useFactory: (config: ConfigService): Auth => {
        const app = initializeApp({
          credential: cert({
            projectId: config.getOrThrow<string>('FIREBASE_PROJECT_ID'),
            clientEmail: config.getOrThrow<string>('FIREBASE_CLIENT_EMAIL'),
            privateKey: config
              .getOrThrow<string>('FIREBASE_PRIVATE_KEY')
              .replace(/\\n/g, '\n'),
          }),
        });
        return getAuth(app);
      },
      inject: [ConfigService],
    },
  ],
  exports: [FIREBASE_AUTH],
})
export class FirebaseAdminModule {}
