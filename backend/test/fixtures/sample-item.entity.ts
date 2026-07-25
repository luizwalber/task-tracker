import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

/**
 * Exists only to exercise UserScopedRepository generically in tests, before any real
 * domain entity (Task, TaskOccurrence, ...) is built. Not part of the production schema.
 */
@Entity({ name: 'sample_items_test_fixture' })
export class SampleItemEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text', name: 'user_id' })
  userId: string;

  @Column({ type: 'text' })
  label: string;
}
