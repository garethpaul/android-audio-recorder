# Recorder Device Verification Checklist

Status: Completed

## Problem

Portable contracts cover recorder/player ownership, cleanup, file deletion, and
lifecycle guards, but no checklist defines the compatible-device evidence
required before claiming microphone, storage, recording, or playback behavior.

## Requirements

1. Add an exact-commit matrix for build, permission, recording, playback,
   failure cleanup, lifecycle, storage, and privacy behavior.
2. Require sanitized toolchain, emulator/device, result, and log evidence.
3. Keep repository checks separate from unexecuted Android media scenarios.
4. Add mutation-sensitive contracts for the checklist and completion evidence.

## Scope Boundaries

- Do not modernize Gradle, Android APIs, target SDK, or dependencies.
- Do not add recordings, APKs, device exports, paths, logs, or signing material.
- Do not claim emulator or physical-device execution from portable checks.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- `sh -n scripts/check-baseline.sh` and the focused recorder baseline checker
  passed.
- Repository-root and external-working-directory `make check` passed all
  portable contracts and retained the existing bounded SDK behavior.
- Twelve hostile mutations were rejected for removing checklist, permission,
  startup, recording, playback, lifecycle, privacy, unexecuted-result,
  documentation, or completed-plan evidence.
- No Android SDK, emulator, physical-device, microphone, or media scenario was executed; every runtime matrix row remains `not run`.
