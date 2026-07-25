import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { Auth } from 'firebase-admin/auth';
import type { Request } from 'express';
import type { AuthenticatedUser } from '../../domain/auth/authenticated-user';
import { FIREBASE_AUTH } from './firebase-auth.token';

export type RequestWithUser = Request & { user?: AuthenticatedUser };

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(@Inject(FIREBASE_AUTH) private readonly firebaseAuth: Auth) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<RequestWithUser>();
    const header = request.headers['authorization'];
    const token =
      typeof header === 'string'
        ? header.replace(/^Bearer\s+/i, '')
        : undefined;

    if (!token) {
      throw new UnauthorizedException('Missing bearer token');
    }

    try {
      const decoded = await this.firebaseAuth.verifyIdToken(token);
      request.user = { uid: decoded.uid } satisfies AuthenticatedUser;
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}
