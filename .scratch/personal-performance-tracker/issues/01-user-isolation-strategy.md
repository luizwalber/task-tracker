Type: grilling
Status: resolved

## Question

How should per-user isolation be designed across layers — a guard validating the Firebase ID token, propagating `userId` down to the use case, repositories that cannot build a query without a user scope (a base repository injecting the filter) — and is it worth adding Postgres Row-Level Security (`SET LOCAL app.user_id` per transaction) as an extra safety net, or is code-level scoping in the repository enough for a portfolio project? Also define how to automatically test (integration test) that one user cannot reach another user's data.

Resolve with a clear recommendation (RLS yes/no, and why) and the base repository / guard design as a code signature.

## Answer

**Decision: no RLS.** Code-level scoping in a base repository is the chosen design — the defense is structural (impossible to build a query without a `userId`), not an extra network hop in Postgres. Rationale: RLS earns its complexity when the same database is queried by multiple trust boundaries that could bypass the app layer (raw SQL consoles, other services, admin tooling) — this project has exactly one API surface and one trust boundary, so RLS would be defense-in-depth for a threat that doesn't exist here yet. In an interview, the defensible answer is "I evaluated RLS and skipped it because the single-writer topology doesn't need a second enforcement point — here's the structural alternative," not silence on the topic.

**Guard**: `FirebaseAuthGuard implements CanActivate` verifies the ID token via the Firebase Admin SDK and attaches `request.user = { uid: string }`. It never queries the app's own user table — Firebase is the identity source of truth; the app's `users` table (if any) is just a projection keyed by `uid`.

**Propagation**: explicit, not ambient. A `@CurrentUserId()` param decorator reads `request.user.uid` in the controller, which passes it as a field on the use case's input DTO — never via a request-scoped provider or AsyncLocalStorage. This keeps use cases framework-agnostic and trivially unit-testable (construct the DTO, no HTTP mocking needed).

```typescript
// presentation
@Get(':taskId')
getTask(@CurrentUserId() userId: string, @Param('taskId') taskId: string) {
  return this.getTaskUseCase.execute({ userId, taskId });
}

// application
class GetTaskUseCase {
  execute(input: { userId: string; taskId: string }): Promise<TaskDto> { /* ... */ }
}
```

**Base repository**: an abstract class that exposes only user-scoped query methods — no method accepts a query without `userId`, and the underlying TypeORM `Repository<T>` is never exposed to callers, so there is no escape hatch.

```typescript
abstract class UserScopedRepository<T extends { userId: string }> {
  protected constructor(protected readonly repo: Repository<T>) {}

  protected scoped(userId: string): SelectQueryBuilder<T> {
    return this.repo.createQueryBuilder('e').where('e.userId = :userId', { userId });
  }

  findOneForUser(userId: string, id: string): Promise<T | null> {
    return this.scoped(userId).andWhere('e.id = :id', { id }).getOne();
  }
}
```

**Automated isolation test**: one reusable contract test, not one bespoke test per repository — run it against every `UserScopedRepository` implementation as a table-driven suite:

```typescript
function itIsolatesByUser<T>(repo: UserScopedRepository<T>, seed: (userId: string) => Promise<T>) {
  it('never returns another user data', async () => {
    const owned = await seed('user-a');
    const result = await repo.findOneForUser('user-b', owned.id);
    expect(result).toBeNull(); // 404, not 403 — don't leak existence
  });
}
```

This turns "no cross-user leak" into an invariant enforced once per repository, not a hope re-verified ad hoc per endpoint.

