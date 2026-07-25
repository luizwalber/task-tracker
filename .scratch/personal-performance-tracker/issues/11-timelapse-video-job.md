Type: grilling
Status: resolved

## Question

The timelapse mini-video is generated server-side via a daily job (FFmpeg), deleting previous videos. How should progress from start to finish be exposed to the Flutter client — polling, Server-Sent Events, or WebSocket — and why, considering it's a Flutter Web + Desktop app with no offline cache (connection always available) and that the job runs once a day (not a real-time user-triggered action, unless the user can also trigger generation on demand)?

Resolve with the chosen mechanism and its justification, and whether there's on-demand generation in addition to the daily job.

## Answer

**No on-demand generation — only the automatic daily job.** This resolves the polling/SSE/WebSocket question by dissolving it: since the FFmpeg job runs on a server cron schedule with no user in the loop triggering it, there is never a live session watching a progress bar for it. The user opens the app well after the job ran (or before it's run yet today) — there's nothing to stream to.

**Client contract**: a plain `GET /timelapse/status` returns `{ status: 'READY' | 'GENERATING' | 'FAILED' | 'NOT_YET_GENERATED', generatedAt?: LocalDate, videoUrl?: string }`, queried once when the reports/timelapse screen opens (and optionally re-queried on manual pull-to-refresh) — no streaming channel of any kind. `GENERATING` only appears in the rare case the user opens the app during the job's brief execution window; there's no expectation of watching it tick toward completion, just a "still working on it, check back" state.

**Why not build SSE/WebSocket anyway for the portfolio value**: unlike the earlier SQL-sophistication and job-queue trade-offs (where "worth showing off despite not being strictly needed" was a live option), a streaming mechanism here would have no real trigger to attach to — there's no user action starting the job to report progress on. Adding one would mean inventing a reason for it (e.g., a fake on-demand button) rather than solving something the actual requirement produces.

**Cleanup**: the daily job deletes all previous timelapse video files before writing the new one, per the brief — a single current video file per user at any time, matching the `NOT_YET_GENERATED` → `READY` transition the status endpoint exposes.

