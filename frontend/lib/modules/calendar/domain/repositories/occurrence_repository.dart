import '../entities/upsert_occurrence_result.dart';

abstract class OccurrenceRepository {
  /// Idempotent upsert keyed by taskId + date. Never throws away the caller's
  /// drag value — network failures surface as a thrown exception so the
  /// caller can keep the optimistic value and retry.
  Future<UpsertOccurrenceResult> upsert({
    required String taskId,
    required DateTime date,
    required int percentage,
  });
}
