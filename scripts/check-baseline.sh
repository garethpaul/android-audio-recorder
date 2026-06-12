#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/gpj/android_recorder/MainActivity.java"
LAYOUT="$ROOT_DIR/app/src/main/res/layout/activity_main.xml"
README="$ROOT_DIR/README.md"
RES_DIR="$ROOT_DIR/app/src/main/res"
CI_PLAN="$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"
CI_WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"

require_button_attribute() {
  button_id=$1
  attribute=$2
  message=$3

  if ! awk -v button_id="android:id=\"@+id/$button_id\"" -v attribute="$attribute" '
    /<ImageButton/ {
      in_button = 1
      block = ""
    }
    in_button {
      block = block $0 "\n"
    }
    in_button && /\/>/ {
      if (index(block, button_id) && index(block, attribute)) {
        found = 1
      }
      in_button = 0
    }
    END {
      exit found ? 0 : 1
    }
  ' "$LAYOUT"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

expected_ci_workflow() {
  cat <<'EOF'
name: Check

on:
  push:
    branches:
      - master
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: check-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  check:
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - name: Check out repository
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
        with:
          persist-credentials: false

      - name: Run baseline
        run: make check
        env:
          ANDROID_HOME: ""
          ANDROID_SDK_ROOT: ""
EOF
}

if grep -Fq "onPlay(mStartPlaying[0]);" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play button must not dispatch onPlay before branch-specific UI updates." >&2
  exit 1
fi

if ! grep -Fq 'android:allowBackup="false"' "$ROOT_DIR/app/src/main/AndroidManifest.xml"; then
  printf '%s\n' "Recorder must disable Android backups for local audio state." >&2
  exit 1
fi

if grep -Fq 'android:allowBackup="true"' "$ROOT_DIR/app/src/main/AndroidManifest.xml"; then
  printf '%s\n' "Recorder must not allow Android backups." >&2
  exit 1
fi

if grep -Fq 'android.permission.WRITE_EXTERNAL_STORAGE' "$ROOT_DIR/app/src/main/AndroidManifest.xml"; then
  printf '%s\n' "Recorder must not request broad external storage writes." >&2
  exit 1
fi

if ! grep -Fq 'android.permission.RECORD_AUDIO' "$ROOT_DIR/app/src/main/AndroidManifest.xml"; then
  printf '%s\n' "Recorder must keep the microphone permission explicit." >&2
  exit 1
fi

if grep -Fq "Environment.getExternalStorageDirectory()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder must not write recordings to the external storage root." >&2
  exit 1
fi

if ! grep -Fq "getExternalFilesDir(null)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder must store recordings under app-specific external files." >&2
  exit 1
fi

if ! grep -Fq "getFilesDir()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder must fall back to app-internal storage when external files are unavailable." >&2
  exit 1
fi

if ! grep -Fq "onPlay(true)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play-start branch must call onPlay(true)." >&2
  exit 1
fi

if ! grep -Fq "onPlay(false)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play-stop branch must call onPlay(false)." >&2
  exit 1
fi

if ! grep -Fq "private boolean onRecord(boolean start)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Record dispatch must report whether media startup succeeded." >&2
  exit 1
fi

if ! grep -Fq "private boolean onPlay(boolean start)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play dispatch must report whether media startup succeeded." >&2
  exit 1
fi

if ! grep -Fq "private boolean startRecording()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "startRecording must return a success flag." >&2
  exit 1
fi

if ! grep -Fq "private boolean startPlaying()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "startPlaying must return a success flag." >&2
  exit 1
fi

if grep -Fq "final boolean[] mStartPlaying" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Playback state must not be hidden in an onCreate-local array." >&2
  exit 1
fi

if grep -Fq "final boolean[] mStartRecording" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recording state must not be hidden in an onCreate-local array." >&2
  exit 1
fi

if ! grep -Fq "private boolean mStartRecording = true;" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recording state must be tracked as an activity field." >&2
  exit 1
fi

if ! grep -Fq "private void resetRecordingControls()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recording control reset must be centralized." >&2
  exit 1
fi

if ! grep -Fq "private void resetPlaybackControls()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Playback control reset must be centralized." >&2
  exit 1
fi

if ! grep -Fq "ActionBar actionBar = getActionBar();" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder startup must store the optional action bar before use." >&2
  exit 1
fi

if ! grep -Fq "if (actionBar != null)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder startup must guard missing action bars." >&2
  exit 1
fi

if ! grep -Fq "if (mRecordButton == null || mPlayButton == null)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder startup must guard missing record/play buttons." >&2
  exit 1
fi

if ! grep -Fq '"Recorder controls are not available"' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder startup must log missing control lookups." >&2
  exit 1
fi

if ! grep -Fq "mPlayer.setOnCompletionListener" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Playback must reset controls when media completes." >&2
  exit 1
fi

if ! grep -Fq "public void onCompletion(MediaPlayer mp)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Playback completion listener must handle MediaPlayer completion." >&2
  exit 1
fi

if ! grep -Fq "mPlayer.setOnErrorListener" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Playback must reset controls when media playback errors." >&2
  exit 1
fi

if ! grep -Fq "public boolean onError(MediaPlayer mp, int what, int extra)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Playback error listener must handle MediaPlayer errors." >&2
  exit 1
fi

if ! awk '
  /public boolean onError\(MediaPlayer mp, int what, int extra\)/ {
    in_error = 1
  }
  in_error && /releasePlayer\(\);/ {
    found_release = 1
  }
  in_error && /resetPlaybackControls\(\);/ {
    found_reset = 1
  }
  in_error && /return true;/ {
    found_return = 1
  }
  in_error && /^                }$/ {
    exit found_release && found_reset && found_return ? 0 : 1
  }
  END {
    exit found_release && found_reset && found_return ? 0 : 1
  }
' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Playback error listener must release, reset, and consume handled errors." >&2
  exit 1
fi

if ! grep -Fq "mStartPlaying = true;" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Playback reset must return the play state to idle." >&2
  exit 1
fi

if ! grep -Fq "mStartRecording = true;" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recording reset must return the record state to idle." >&2
  exit 1
fi

if ! grep -Fq "resetRecordingControls();" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder lifecycle must reset recording controls after cleanup." >&2
  exit 1
fi

if ! grep -Fq "if (onRecord(true))" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Record UI must only enter recording state after startup succeeds." >&2
  exit 1
fi

if ! grep -Fq "return stopRecording();" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder stop results must propagate through onRecord()." >&2
  exit 1
fi

for stop_contract in \
  "private boolean stopRecording()" \
  "boolean stopped = false;" \
  "stopped = true;" \
  "return stopped;" \
  "if (onRecord(false))"; do
  if ! grep -Fq "$stop_contract" "$MAIN_ACTIVITY"; then
    printf '%s\n' "Recorder finalization must keep contract: $stop_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "if (onPlay(true))" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play UI must only enter playback state after startup succeeds." >&2
  exit 1
fi

if ! grep -Fq "private void releaseRecorder()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder cleanup must be centralized in releaseRecorder()." >&2
  exit 1
fi

if ! grep -Fq "private void releasePlayer()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Player cleanup must be centralized in releasePlayer()." >&2
  exit 1
fi

ON_PAUSE=$(awk '/public void onPause\(\)/,/^    }/' "$MAIN_ACTIVITY")
if ! printf '%s\n' "$ON_PAUSE" | grep -Fq "stopRecording();"; then
  printf '%s\n' "Recorder lifecycle cleanup must stop active recording before release." >&2
  exit 1
fi
if ! printf '%s\n' "$ON_PAUSE" | grep -Fq "stopPlaying();"; then
  printf '%s\n' "Recorder lifecycle cleanup must stop active playback before release." >&2
  exit 1
fi
if printf '%s\n' "$ON_PAUSE" | grep -Eq "release(Recorder|Player)\(\);"; then
  printf '%s\n' "Recorder lifecycle cleanup must not bypass guarded stop methods." >&2
  exit 1
fi

if ! grep -Fq "catch (RuntimeException e)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder/player stop and start failures must be guarded." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md is missing." >&2
  exit 1
fi

if [ ! -f "$CI_WORKFLOW" ]; then
  printf '%s\n' "GitHub Actions check workflow is missing." >&2
  exit 1
fi

workflow_count=0
workflow_name=""
for workflow_path in "$ROOT_DIR"/.github/workflows/*.yml "$ROOT_DIR"/.github/workflows/*.yaml; do
  if [ ! -f "$workflow_path" ]; then
    continue
  fi
  workflow_count=$((workflow_count + 1))
  workflow_name=$(basename "$workflow_path")
done

if [ "$workflow_count" -ne 1 ] || [ "$workflow_name" != "check.yml" ]; then
  printf '%s\n' "check.yml must remain the only approved GitHub Actions workflow." >&2
  exit 1
fi

if [ "$(cat "$CI_WORKFLOW")" != "$(expected_ci_workflow)" ]; then
  printf '%s\n' "GitHub Actions check workflow must match the approved SDK-free security baseline." >&2
  exit 1
fi

for make_contract in \
  'ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' \
  'ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))'; do
  if ! grep -Fq "$make_contract" "$ROOT_DIR/Makefile"; then
    printf '%s\n' "Makefile must keep contract: $make_contract" >&2
    exit 1
  fi
done

if grep -Fq "/home/gjones" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must not embed a maintainer-specific Android SDK path." >&2
  exit 1
fi

if ! grep -Fq "GitHub Actions" "$README"; then
  printf '%s\n' "README must document the GitHub Actions check." >&2
  exit 1
fi

if [ -f "$ROOT_DIR/app/src/main/res/menu/menu_main.xml" ]; then
  printf '%s\n' "Unused starter menu resource must not be restored." >&2
  exit 1
fi

for image in logo play record stop; do
  if [ ! -f "$RES_DIR/drawable-nodpi/$image.png" ]; then
    printf '%s\n' "Recorder image must stay in drawable-nodpi: $image.png" >&2
    exit 1
  fi
done

if [ -d "$RES_DIR/drawable" ] && find "$RES_DIR/drawable" -name '*.png' | grep -q .; then
  printf '%s\n' "Recorder PNG controls must not live in density-scaled drawable/." >&2
  exit 1
fi

if grep -Fq 'android:background="#444C58"' "$LAYOUT"; then
  printf '%s\n' "Recorder background must live in the theme to avoid layout overdraw." >&2
  exit 1
fi

if ! grep -Fq 'android:contentDescription="@string/record_button_description"' "$LAYOUT"; then
  printf '%s\n' "Record button must have an accessibility description." >&2
  exit 1
fi

if ! grep -Fq 'android:contentDescription="@string/play_button_description"' "$LAYOUT"; then
  printf '%s\n' "Play button must have an accessibility description." >&2
  exit 1
fi

require_button_attribute "record" 'android:src="@drawable/record"' \
  "Record button must start with the record icon."
require_button_attribute "play" 'android:src="@drawable/play"' \
  "Play button must start with the play icon."
require_button_attribute "play" 'android:visibility="invisible"' \
  "Play button must remain hidden until a recording exists."

if ! grep -Fq "LintError" "$ROOT_DIR/app/lint.xml"; then
  printf '%s\n' "lint.xml must document the obsolete lint API database limitation." >&2
  exit 1
fi

if ! grep -Fq "IconMissingDensityFolder" "$ROOT_DIR/app/lint.xml"; then
  printf '%s\n' "lint.xml must document the nodpi bitmap asset baseline." >&2
  exit 1
fi

if ! grep -Fq "./gradlew lint --no-daemon" "$README"; then
  printf '%s\n' "README must document Gradle lint verification." >&2
  exit 1
fi

if ! grep -Fq "./gradlew test --no-daemon" "$README"; then
  printf '%s\n' "README must document Gradle test verification." >&2
  exit 1
fi

if ! grep -Fq "./gradlew assembleDebug --no-daemon" "$README"; then
  printf '%s\n' "README must document Gradle build verification." >&2
  exit 1
fi

if ! grep -Fq "record/play startup failures" "$README"; then
  printf '%s\n' "README must document recorder startup-failure UI handling." >&2
  exit 1
fi

if ! grep -Fq "playback completion" "$README"; then
  printf '%s\n' "README must document playback completion UI handling." >&2
  exit 1
fi

if ! grep -Fq "playback errors" "$README"; then
  printf '%s\n' "README must document playback error UI handling." >&2
  exit 1
fi

if ! grep -Fq "lifecycle cleanup resets" "$README"; then
  printf '%s\n' "README must document lifecycle recording-control reset handling." >&2
  exit 1
fi

if ! grep -Fq "recording finalization failures" "$README"; then
  printf '%s\n' "README must document recording finalization failure handling." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-recorder-startup-ui-state.md"; then
  printf '%s\n' "Recorder startup UI state plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-recorder-playback-completion-ui.md"; then
  printf '%s\n' "Recorder playback completion UI plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-recorder-recording-lifecycle-reset.md"; then
  printf '%s\n' "Recorder recording lifecycle reset plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-recorder-playback-error-ui.md"; then
  printf '%s\n' "Recorder playback error UI plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-10-recorder-stop-result.md" || \
   ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-10-recorder-stop-result.md"; then
  printf '%s\n' "Recorder stop-result plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$CI_PLAN" ]; then
  printf '%s\n' "Recorder CI baseline plan is missing." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$CI_PLAN" || ! grep -Fq "make check" "$CI_PLAN"; then
  printf '%s\n' "Recorder CI baseline plan must record completed status and make check verification." >&2
  exit 1
fi

printf '%s\n' "Audio recorder baseline checks passed."
