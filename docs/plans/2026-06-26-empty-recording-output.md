# Empty Recording Output Rejection

Status: Completed.

## Problem

`RecordingFileStore` treated every owned regular file as a valid recording.
A zero-byte pending file could therefore replace the last finalized capture,
and a zero-byte finalized file was exposed to the playback controls even though
it contained no audio data.

## Decision

Require recording output to be both owner-controlled and non-empty before it
can be promoted or returned for playback. Keep the existing regular-file check
for deletion so failed empty output can still be cleaned up safely.

## Verification

- Host behavior tests cover an empty replacement preserving the prior capture.
- Host behavior tests cover an empty finalized file remaining unavailable.
- The hostile mutation gate proves that weakening the non-empty boundary is
  rejected by the canonical tests.
