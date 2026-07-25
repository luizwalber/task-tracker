import { Injectable } from '@nestjs/common';
import { UserEntity } from '../../infrastructure/persistence/user.entity';
import { UserRepository } from '../../infrastructure/persistence/user.repository';

export interface EnsureUserProjectionInput {
  uid: string;
}

@Injectable()
export class EnsureUserProjectionUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  execute(input: EnsureUserProjectionInput): Promise<UserEntity> {
    return this.userRepository.findOrCreate(input.uid);
  }
}
