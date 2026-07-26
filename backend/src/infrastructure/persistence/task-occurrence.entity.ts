import { Column, CreateDateColumn, Entity, Index, PrimaryColumn, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'task_occurrences' })
@Index(['userId', 'date'])
export class TaskOccurrenceEntity {
  @PrimaryColumn({ type: 'text', name: 'user_id' })
  userId: string;

  @PrimaryColumn({ type: 'uuid', name: 'task_id' })
  taskId: string;

  @PrimaryColumn({ type: 'date' })
  date: string;

  @Column({ type: 'smallint' })
  percentage: number;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}
