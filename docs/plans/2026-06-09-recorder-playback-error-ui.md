# Recorder Playback Error UI

Date: 2026-06-09
Status: Completed

## Problem

Playback completion already returns the recorder UI to its idle state, but
`MediaPlayer` runtime errors after startup were not handled by a listener. A
playback error could leave the stop icon visible even though playback had
failed and the player needed cleanup.

## Scope

- Preserve the existing two-button recorder flow.
- Keep successful playback and manual stop behavior unchanged.
- Do not add broader media API modernization or runtime permission handling.
- Keep verification available without an Android SDK.

## Work Completed

- Added a `MediaPlayer.OnErrorListener` after successful playback preparation.
- Released the player and reset playback controls when playback errors.
- Consumed handled playback errors so Android does not also dispatch completion
  behavior for the same failure.
- Extended the SDK-free baseline and project documentation for playback-error
  UI reset behavior.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
