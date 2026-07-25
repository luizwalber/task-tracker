import { Controller, Get, UseGuards } from '@nestjs/common';
import { EnsureUserProjectionUseCase } from '../application/users/ensure-user-projection.use-case';
import { FirebaseAuthGuard } from '../infrastructure/auth/firebase-auth.guard';
import type { AuthenticatedUser } from '../domain/auth/authenticated-user';
import { CurrentUser } from './current-user.decorator';

@UseGuards(FirebaseAuthGuard)
@Controller('me')
export class MeController {
  constructor(
    private readonly ensureUserProjection: EnsureUserProjectionUseCase,
  ) {}

  @Get()
  async getMe(@CurrentUser() user: AuthenticatedUser) {
    const projection = await this.ensureUserProjection.execute({
      uid: user.uid,
    });
    return { id: projection.id, createdAt: projection.createdAt };
  }
}
