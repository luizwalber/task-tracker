/**
 * Thrown when a taskId doesn't exist or doesn't belong to the requesting
 * user. Presentation maps this to 404, never 403 — same "don't leak
 * existence" rule as OwnershipViolationError.
 */
export class TaskNotFoundError extends Error {
  constructor(taskId: string) {
    super(`Task ${taskId} not found`);
  }
}
