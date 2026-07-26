import { Column, CreateDateColumn, Entity, Index, PrimaryColumn } from 'typeorm';

@Entity({ name: 'tasks' })
export class TaskEntity {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @Index()
  @Column({ type: 'text', name: 'user_id' })
  userId: string;

  @Column({ type: 'text' })
  name: string;

  @Column({
    type: 'numeric',
    precision: 3,
    scale: 1,
    transformer: { to: (v: number) => v, from: (v: string) => Number(v) },
  })
  weight: number;

  @Column({ type: 'date', name: 'starts_on' })
  startsOn: string;

  @Column({ type: 'date', name: 'ends_on', nullable: true })
  endsOn: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt?: Date;
}
