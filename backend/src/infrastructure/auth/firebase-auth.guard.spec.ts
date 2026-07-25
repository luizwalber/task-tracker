import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { FirebaseAuthGuard, RequestWithUser } from './firebase-auth.guard';

function fakeRequest(authorization?: string): RequestWithUser {
  return {
    headers: authorization ? { authorization } : {},
  } as unknown as RequestWithUser;
}

function contextFor(request: RequestWithUser): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => request,
    }),
  } as unknown as ExecutionContext;
}

describe('FirebaseAuthGuard', () => {
  it('rejects a request with no Authorization header', async () => {
    const guard = new FirebaseAuthGuard({ verifyIdToken: jest.fn() } as never);
    await expect(guard.canActivate(contextFor(fakeRequest()))).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('rejects a request whose token fails verification', async () => {
    const verifyIdToken = jest.fn().mockRejectedValue(new Error('invalid'));
    const guard = new FirebaseAuthGuard({ verifyIdToken } as never);
    await expect(
      guard.canActivate(contextFor(fakeRequest('Bearer bad-token'))),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('attaches the decoded uid to the request and allows the request through on a valid token', async () => {
    const verifyIdToken = jest.fn().mockResolvedValue({ uid: 'user-a' });
    const guard = new FirebaseAuthGuard({ verifyIdToken } as never);
    const request = fakeRequest('Bearer good-token');

    const result = await guard.canActivate(contextFor(request));

    expect(result).toBe(true);
    expect(verifyIdToken).toHaveBeenCalledWith('good-token');
    expect(request.user).toEqual({ uid: 'user-a' });
  });
});
