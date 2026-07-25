import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserEntity } from './user.entity';

@Injectable()
export class UserRepository {
  constructor(
    @InjectRepository(UserEntity) private readonly repo: Repository<UserEntity>,
  ) {}

  async findOrCreate(uid: string): Promise<UserEntity> {
    const existing = await this.repo.findOneBy({ id: uid });
    if (existing) return existing;
    return this.repo.save(this.repo.create({ id: uid }));
  }
}
