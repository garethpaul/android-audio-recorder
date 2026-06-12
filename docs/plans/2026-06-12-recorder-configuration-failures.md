# Recorder Configuration Failure Guard

Status: Completed

## Context

`startRecording()` catches failures from `prepare()` and `start()`, but creates
and configures `MediaRecorder` before entering that guarded block. Microphone
source selection, output format, output path, or encoder configuration can
throw runtime failures for denied permissions, unsupported devices, invalid
state, or storage problems. Those failures currently escape the click handler
and crash the activity instead of releasing media resources and preserving the
idle controls.

## Prioritized Scope

1. Guard the complete recorder construction, configuration, prepare, and start
   sequence with the existing boolean startup contract.
2. Release any partially created recorder for both checked I/O and runtime
   failures.
3. Keep diagnostics generic and avoid recording paths or device details.
4. Preserve successful recording, guarded stop/finalization, pause cleanup,
   playback gating, app-specific storage, and existing UI transitions.
5. Extend the SDK-free baseline and project documentation with configuration
   failure ordering requirements.

## Implementation Units

### Complete Startup Guard

Files: `app/src/main/java/gpj/android_recorder/MainActivity.java`

- Keep `releaseRecorder()` before a new startup attempt.
- Move recorder construction and every configuration call inside the existing
  `try` block.
- Return `true` only after `start()` succeeds.
- Keep separate checked-I/O and runtime diagnostics, releasing the recorder on
  both paths and returning `false`.

### Static Regression Contracts

Files: `scripts/check-baseline.sh`

- Require the startup `try` to precede recorder construction and configuration.
- Require construction, source, format, output file, encoder, prepare, and
  start to occur before both failure handlers and the successful return.
- Require both catches to release the recorder and preserve the completed plan.

### Documentation

Files: `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`

- Document fail-closed handling for recorder construction and configuration.
- Retain the explicit Android SDK/device verification limitation.

## Risks

- This broadens the existing runtime catch to setup operations that previously
  crashed. The user-visible behavior intentionally remains the current idle UI
  because the click handler changes controls only after a successful return.
- Static checks cannot prove device-specific microphone or media behavior. A
  compatible Android SDK build and device/emulator exercise remain required
  before claiming runtime coverage.

## Verification

- `make lint`
- `make test`
- `make build`
- `make check`
- Static mutation checks for recorder startup ordering and cleanup
- `git diff --check`
