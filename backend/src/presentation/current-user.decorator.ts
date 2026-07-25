import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { AuthenticatedUser } from '../domain/auth/authenticated-user';

/** Local and minimal on purpose — this file only ever reads `.user`, so it
 * doesn't need infrastructure's full `RequestWithUser` (Express `Request` +
 * the user field); a distinct name avoids reading as the same type. */
type HasAuthenticatedUser = { user?: AuthenticatedUser };

export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): AuthenticatedUser | undefined => {
    const request = ctx.switchToHttp().getRequest<HasAuthenticatedUser>();
    return request.user;
  },
);
