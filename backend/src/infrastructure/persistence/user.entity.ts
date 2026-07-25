import { CreateDateColumn, Entity, PrimaryColumn } from 'typeorm';

@Entity({ name: 'users' })
export class UserEntity {
  @PrimaryColumn({ type: 'text' })
  id: string; // Firebase uid — identity source of truth is Firebase, this is just a projection

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;
}
