import {
  UserOwned,
  UserScopedRepository,
} from '../../src/infrastructure/persistence/user-scoped.repository';

/**
 * Reusable cross-user isolation invariant, run against every UserScopedRepository
 * implementation instead of writing a bespoke test per repository/endpoint.
 */
export function itIsolatesByUser<T extends UserOwned>(
  getRepo: () => UserScopedRepository<T>,
  seed: (userId: string) => Promise<T>,
): void {
  it("never returns another user's data by id", async () => {
    const owned = await seed('user-a');
    const result = await getRepo().findOneForUser('user-b', owned.id);
    expect(result).toBeNull(); // 404, not 403 — never leak existence
  });

  it("never lists another user's data", async () => {
    await seed('user-a');
    const all = await getRepo().findAllForUser('user-b');
    expect(all).toHaveLength(0);
  });

  it("returns the owner's own data by id", async () => {
    const owned = await seed('user-a');
    const result = await getRepo().findOneForUser('user-a', owned.id);
    expect(result?.id).toBe(owned.id);
  });

  it("rejects writing to another user's row", async () => {
    const owned = await seed('user-a');

    await expect(
      getRepo().saveForUser('user-b', { id: owned.id } as Omit<T, 'userId'>),
    ).rejects.toThrow();

    const stillOwnedByA = await getRepo().findOneForUser('user-a', owned.id);
    expect(stillOwnedByA).not.toBeNull();
  });
}
