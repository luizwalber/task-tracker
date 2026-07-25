import { UserEntity } from './user.entity';

/**
 * The single list of TypeORM entities for this app — both the migration
 * DataSource and the runtime TypeOrmModule import this instead of declaring
 * their own copy, so adding an entity is a one-file change, not two.
 */
export const entities = [UserEntity];
