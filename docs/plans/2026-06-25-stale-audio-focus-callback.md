# Stale Audio-Focus Callback Ownership

Status: Completed.

## Problem

Every playback session reused one activity-wide audio-focus listener. A delayed
loss callback from an abandoned request therefore had no identity to compare
with current ownership and could stop a newer player that had already acquired
focus.

## Design

- Allocate a distinct listener for each playback focus request.
- Retain the listener only when focus is granted.
- Ignore callbacks unless the activity still owns that exact listener.
- Detach listener and focus ownership before calling the platform abandonment
  API, then abandon the captured listener rather than the cleared field.
- Preserve existing playback, lifecycle, completion, error, and focus-loss UI
  behavior for the currently owned request.

## Test-First Evidence

- RED: the portable activity contract failed because the activity owned one
  shared final listener without a stale-callback identity guard.
- GREEN: the contract requires exact listener retention, callback identity,
  detach-before-abandon ordering, and abandonment of the captured listener.
- The stale callback guard, exact abandonment target, and detach-before-platform
  ownership rule each reject a hostile mutation; three hostile audio-focus mutations were rejected.
- The existing group-readable-output mutation was corrected to grant group
  readability rather than removing the initial permission reset, restoring the
  intended storage test signal.

## Verification

- `scripts/test-main-activity-contracts.py`
- `scripts/test-review-mutations.sh`
- `scripts/check-baseline.sh`
- Root `make check`
- `make check` through the absolute Makefile path from an external working directory
- Shell and Python syntax checks plus `git diff --check`

## Runtime Boundary

No Android SDK, emulator, physical device, audio-focus contention, microphone,
or media playback scenario was available locally. Portable ownership contracts
do not replace exact-commit device verification.
