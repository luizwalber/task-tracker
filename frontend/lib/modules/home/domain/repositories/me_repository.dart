/// Domain-level contract for fetching the authenticated user's projection.
/// Presentation depends only on this — never on ApiClient/package:http
/// directly — so it can be tested with a fake, no network involved.
abstract class MeRepository {
  /// Returns the raw `GET /me` response body on success. Throws if the
  /// request fails or the backend responds with a non-200 status.
  Future<String> getMe();
}
