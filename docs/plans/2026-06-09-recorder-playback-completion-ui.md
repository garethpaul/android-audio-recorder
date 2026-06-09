---
title: Recorder Playback Completion UI
type: reliability
status: completed
date: 2026-06-09
---

# Recorder Playback Completion UI

## Problem Frame

Playback completion left the UI in its active stop state even though the media
player had finished. Users had to tap the stop icon after completion just to
return the recorder controls to their idle state.

## Scope Boundaries

- Preserve the legacy activity and two-button layout.
- Keep the existing manual stop behavior.
- Do not add runtime permission handling or broader media API modernization.
- Keep verification available without an Android SDK.

## Implementation Units

### U1: Reset Controls On Completion

Files:

- Modify `app/src/main/java/gpj/android_recorder/MainActivity.java`

Approach:

- Attach a `MediaPlayer.OnCompletionListener` after successful prepare.
- Release the player and reset the visible controls when playback completes.
- Keep manual stop using the same playback-control reset path.

### U2: Cover And Document The Contract

Files:

- Modify `scripts/check-baseline.sh`
- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Add SDK-free checks for the completion listener and centralized playback
  reset helper.
- Document the playback completion behavior in the project notes.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `make verify`
- `git diff --check`
