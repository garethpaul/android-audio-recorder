# Recorder Stale Player Callback Guard

Status: Completed

## Context

`MediaPlayer` completion and error callbacks call `releasePlayer()` and reset
the activity controls without confirming that the callback's `mp` argument is
still the retained `mPlayer`. A delayed callback from a player that was stopped
or released can therefore tear down a newer playback instance and reset its UI.

## Requirements

- Ignore completion callbacks whose `MediaPlayer` is not the current retained
  player.
- Ignore stale error callbacks without logging or changing current playback
  state, while still reporting the stale error as handled.
- Perform identity checks before release, logging, or control reset.
- Preserve current completion cleanup, active-player error cleanup, stop
  behavior, recording lifecycle, output cleanup, and generic logs.
- Add mutation-sensitive SDK-free ordering contracts and truthful verification.

## Implementation Units

### U1: Guard Playback Callbacks

**File:** `app/src/main/java/gpj/android_recorder/MainActivity.java`

Add `mPlayer != mp` early returns to the completion and error listeners. Keep
the existing active callback actions and `onError` handled result unchanged.

### U2: Enforce Identity And Ordering

**File:** `scripts/check-baseline.sh`

Require both callback guards, require each guard before release/log/reset, and
ensure the error callback returns `true` on both stale and active paths.

### U3: Document And Verify

**Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, this plan

Document retained-player callback ownership. Run focused hostile mutations,
local and external full gates, diff/artifact/secret scans, and exact-head
hosted verification.

## Scope Boundaries

- Do not change MediaPlayer construction, data source, prepare/start/stop,
  recording behavior, dependencies, permissions, UI layout, or file paths.
- Do not add audio focus, services, background playback, or concurrency
  abstractions.
- Do not claim emulator, device, speaker, or forced callback-race behavior.

## Verification Plan

- Reject hostile mutations removing either guard, moving guards after side
  effects, changing stale error handling, removing guidance, or rolling back
  completed-plan evidence.
- Run `make check` locally and from an isolated external directory.
- Run `git diff --check`, generated-artifact inspection, and credential-shaped
  added-line scans before committing implementation paths.
- Record hosted evidence only after querying the exact pushed head.

## Verification

- The focused checker initially reached only the expected incomplete-plan
  assertion after implementation and documentation were added.
- Eight focused hostile mutations were rejected: both guard removals, both
  guard reorderings, stale and active error-consumption changes, security
  guidance rollback, and completed-plan rollback.
- Mutation testing also exposed and fixed an unbounded checker state that could
  mistake a later unrelated `return true` for the error listener result.
- Local and isolated external-directory `make check` passed the complete
  SDK-free baseline; both truthfully skipped Gradle lint, tests, and build
  because no Android SDK is configured.
- The isolated copy used its own temporary Git index for tracked-file checks.
- `git diff --check`, generated-artifact inspection, and credential-shaped
  added-line scans passed. Hosted exact-head evidence remains pending push.
