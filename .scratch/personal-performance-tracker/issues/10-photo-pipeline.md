Type: grilling
Status: resolved

## Question

Detail the photo pipeline already decided in principle (sharp: resize capping the longer side at ~1600px, lossy WebP q≈85, strip EXIF): where does this processing run (synchronously in the upload request, or an async job?), what happens to the original file (discarded, kept in another volume?), how are files organized in the docker-compose local volume (directory layout by user/task/date), and how are images served with authorization — no guessable public path (an authenticated endpoint serving by signed id, vs a reverse proxy with a token).

Resolve with the full pipeline design and the serving endpoint.

## Answer

**Processing: synchronous, in the upload request.** The upload handler receives the multipart file into memory (e.g., multer's memory storage, never writing the raw upload to disk), pipes it through `sharp` (resize capping the longer side at ~1600px, WebP q≈85, `.rotate()` to bake in EXIF orientation before stripping metadata), and awaits the result before responding. No queue, no worker, no "processing" status to poll — a single personal-use photo per occurrence processes in well under the request timeout with native sharp bindings. A queue would be real infrastructure to show off, but it's solving a throughput problem this app doesn't have.

**Original file: never persisted.** Because the raw upload lives only in memory (not a temp file), there's nothing to clean up — the only bytes that ever touch the volume are the final processed WebP. This is simpler than "process then delete the original" and incidentally better for privacy: an EXIF-laden raw photo never exists on disk even transiently.

**Volume layout**: `/data/photos/{userId}/{taskId}/{date}.webp`. This mirrors the occurrence's own natural key (`userId + taskId + date`) exactly — no random id needed, the path is trivially derivable from the occurrence being upserted, and re-uploading a photo for the same occurrence is a plain overwrite, consistent with the occurrence upsert already being idempotent.

**Serving: an authenticated endpoint, reusing the isolation machinery from [User isolation strategy](01-user-isolation-strategy.md).** `GET /occurrences/:taskId/:date/photo` sits behind the same `FirebaseAuthGuard`; the handler resolves the occurrence through the same `UserScopedRepository` (so a request for another user's `taskId`/`date` combination 404s, never a permissions error that would leak existence) and streams the file only if that lookup succeeds. No signed-URL/token-expiry mechanism needed — Flutter's `NetworkImage` (or an `Image` widget backed by an authenticated `http.Client`) attaches the same bearer token used for every other API call. This keeps photo access under one isolation model instead of running a second one in parallel.

