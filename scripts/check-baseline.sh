#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/gpj/android_recorder/MainActivity.java"
APP_BUILD="$ROOT_DIR/app/build.gradle"
ROOT_BUILD="$ROOT_DIR/build.gradle"
SETTINGS_GRADLE="$ROOT_DIR/settings.gradle"
GRADLE_PROPERTIES="$ROOT_DIR/gradle.properties"
WRAPPER_PROPERTIES="$ROOT_DIR/gradle/wrapper/gradle-wrapper.properties"
MANIFEST="$ROOT_DIR/app/src/main/AndroidManifest.xml"
LAYOUT="$ROOT_DIR/app/src/main/res/layout/activity_main.xml"
README="$ROOT_DIR/README.md"
SECURITY="$ROOT_DIR/SECURITY.md"
RES_DIR="$ROOT_DIR/app/src/main/res"
CI_PLAN="$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"
INTERRUPTED_RECORDING_PLAN="$ROOT_DIR/docs/plans/2026-06-12-interrupted-recording-cleanup.md"
FAILED_START_PLAN="$ROOT_DIR/docs/plans/2026-06-13-recorder-failed-start-file-cleanup.md"
STOP_FAILURE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-recorder-stop-failure-file-cleanup.md"
STALE_PLAYER_PLAN="$ROOT_DIR/docs/plans/2026-06-13-recorder-stale-player-callback.md"
RECORDER_ERROR_PLAN="$ROOT_DIR/docs/plans/2026-06-13-recorder-runtime-error-callback.md"
HOSTED_ANDROID_PLAN="$ROOT_DIR/docs/plans/2026-06-12-hosted-android-verification.md"
WRAPPER_PLAN="$ROOT_DIR/docs/plans/2026-06-12-gradle-wrapper-verification.md"
CI_WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
CODEOWNERS="$ROOT_DIR/.github/CODEOWNERS"
EXPECTED_FILE=$(mktemp "${TMPDIR:-/tmp}/android-audio-recorder-expected.XXXXXX")
trap 'rm -f "$EXPECTED_FILE"' EXIT HUP INT TERM

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

env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true

concurrency:
  group: check-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  check:
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    steps:
      - name: Check out repository
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
        with:
          persist-credentials: false

      - name: Install Android SDK packages
        run: '"${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "platforms;android-22" "build-tools;24.0.3"'

      - name: Set up Java 8
        uses: actions/setup-java@be666c2fcd27ec809703dec50e508c2fdc7f6654 # v5.2.0
        with:
          distribution: corretto
          java-version: "8"

      - name: Run full verification
        run: make check
EOF
}

if find "$ROOT_DIR/.github" "$ROOT_DIR/scripts" "$ROOT_DIR/app" "$ROOT_DIR/gradle" \
  "$ROOT_DIR/Makefile" "$ROOT_DIR/build.gradle" "$ROOT_DIR/settings.gradle" \
  "$ROOT_DIR/gradle.properties" "$ROOT_DIR/gradlew" "$ROOT_DIR/gradlew.bat" \
  -type l -print | grep -q .; then
  printf '%s\n' "Protected build, CI, and app paths must not contain symbolic links." >&2
  exit 1
fi

if grep -Fq "onPlay(mStartPlaying[0]);" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play button must not dispatch onPlay before branch-specific UI updates." >&2
  exit 1
fi

cat > "$EXPECTED_FILE" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="gpj.android_recorder" >
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <application
        android:allowBackup="false"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/AppTheme" >
        <activity
            android:name=".MainActivity"
            android:label="@string/app_name" >
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />

                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF
if ! cmp -s "$MANIFEST" "$EXPECTED_FILE"; then
  printf '%s\n' "Android manifest must match the audited microphone-only privacy baseline." >&2
  exit 1
fi

manifest_paths=$(find "$ROOT_DIR/app/src" -type f -name 'AndroidManifest.xml' -print | LC_ALL=C sort)
if [ "$manifest_paths" != "$MANIFEST" ]; then
  printf '%s\n' "The fixed legacy app must keep one audited Android manifest." >&2
  exit 1
fi

if find "$ROOT_DIR/app/src" -type f \( -name '*.java' -o -name '*.kt' \) \
  -exec grep -E 'java\.net|android\.net|HttpURLConnection|URLConnection|Socket|WebView|org\.apache\.http|okhttp|retrofit' {} + | grep -q .; then
  printf '%s\n' "Recorder source sets must not add direct network clients." >&2
  exit 1
fi

if find "$ROOT_DIR/app" -type f \( -name '*.so' -o -name '*.dex' -o -name '*.jar' -o -name '*.aar' -o -name '*.apk' \) \
  ! -path "$ROOT_DIR/app/build/*" -print | grep -q .; then
  printf '%s\n' "Packaged Android binary payloads are outside the auditable source baseline." >&2
  exit 1
fi

expected_gradle_paths=$(printf '%s\n' \
  "$APP_BUILD" \
  "$ROOT_BUILD" \
  "$GRADLE_PROPERTIES" \
  "$WRAPPER_PROPERTIES" \
  "$SETTINGS_GRADLE" | LC_ALL=C sort)
actual_gradle_paths=$(find "$ROOT_DIR" \
  -path "$ROOT_DIR/.git" -prune -o \
  -path "$ROOT_DIR/app/build" -prune -o \
  -type f \( -name '*.gradle' -o -name 'gradle.properties' -o -name 'gradle-wrapper.properties' \) \
  -print | LC_ALL=C sort)
if [ "$actual_gradle_paths" != "$expected_gradle_paths" ]; then
  printf '%s\n' "The fixed legacy build must not add executable Gradle configuration." >&2
  exit 1
fi

cat > "$EXPECTED_FILE" <<'EOF'
apply plugin: 'com.android.application'

android {
    compileSdkVersion 22
    buildToolsVersion "24.0.3"

    defaultConfig {
        applicationId "gpj.android_recorder"
        minSdkVersion 21
        targetSdkVersion 22
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    compile fileTree(dir: 'libs', include: ['*.jar'])
}
EOF
if ! cmp -s "$APP_BUILD" "$EXPECTED_FILE"; then
  printf '%s\n' "App Gradle configuration must match the audited legacy baseline." >&2
  exit 1
fi

cat > "$EXPECTED_FILE" <<'EOF'
// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        jcenter()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:1.2.3'

        // NOTE: Do not place your application dependencies here; they belong
        // in the individual module build.gradle files
    }
}

allprojects {
    repositories {
        jcenter()
    }
}
EOF
if ! cmp -s "$ROOT_BUILD" "$EXPECTED_FILE"; then
  printf '%s\n' "Root Gradle configuration must match the audited legacy baseline." >&2
  exit 1
fi

printf "%s\n" "include ':app'" > "$EXPECTED_FILE"
if ! cmp -s "$SETTINGS_GRADLE" "$EXPECTED_FILE"; then
  printf '%s\n' "Gradle settings must keep the single audited app module." >&2
  exit 1
fi

cat > "$EXPECTED_FILE" <<'EOF'
# Project-wide Gradle settings.

# IDE (e.g. Android Studio) users:
# Gradle settings configured through the IDE *will override*
# any settings specified in this file.

# For more details on how to configure your build environment visit
# http://www.gradle.org/docs/current/userguide/build_environment.html

# Specifies the JVM arguments used for the daemon process.
# The setting is particularly useful for tweaking memory settings.
# Default value: -Xmx10248m -XX:MaxPermSize=256m
# org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8

# When configured, Gradle will run in incubating parallel mode.
# This option should only be used with decoupled projects. More details, visit
# http://www.gradle.org/docs/current/userguide/multi_project_builds.html#sec:decoupled_projects
# org.gradle.parallel=true
EOF
if ! cmp -s "$GRADLE_PROPERTIES" "$EXPECTED_FILE"; then
  printf '%s\n' "Gradle properties must match the audited legacy baseline." >&2
  exit 1
fi

cat > "$EXPECTED_FILE" <<'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionSha256Sum=1d7c28b3731906fd1b2955946c1d052303881585fc14baedd675e4cf2bc1ecab
distributionUrl=https\://services.gradle.org/distributions/gradle-2.2.1-all.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
if ! cmp -s "$WRAPPER_PROPERTIES" "$EXPECTED_FILE"; then
  printf '%s\n' "Gradle wrapper properties must match the verified legacy runtime contract." >&2
  exit 1
fi

if [ "$(sha256sum "$ROOT_DIR/gradlew" | awk '{print $1}')" != "b187b4c52e749f5760afdd6fadc31b2a98ad35fb249bf0dff03b72650f320409" ] || \
   [ "$(sha256sum "$ROOT_DIR/gradlew.bat" | awk '{print $1}')" != "94102713eb8fb22d032397924c0f38ab2da783ba60d07054339f1190a0c4e2cd" ] || \
   [ "$(sha256sum "$ROOT_DIR/gradle/wrapper/gradle-wrapper.jar" | awk '{print $1}')" != "7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172" ]; then
  printf '%s\n' "Gradle wrapper files must match the reviewed generated hashes." >&2
  exit 1
fi

if ! grep -Fq "Gradle start up script for POSIX generated by Gradle." "$ROOT_DIR/gradlew" || \
   ! grep -Fq "Gradle startup script for Windows" "$ROOT_DIR/gradlew.bat"; then
  printf '%s\n' "Gradle wrapper launchers must retain generated provenance markers." >&2
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

if ! awk '
  /private boolean startRecording\(\)/ { in_method = 1 }
  in_method && /releaseRecorder\(\);/ && !initial_release { initial_release = NR }
  in_method && /try \{/ { try_line = NR }
  in_method && /mRecorder = new MediaRecorder\(\);/ { construct = NR }
  in_method && /mRecorder\.setAudioSource/ { source = NR }
  in_method && /mRecorder\.setOutputFormat/ { format = NR }
  in_method && /mRecorder\.setOutputFile/ { output = NR }
  in_method && /outputConfigured = true;/ { output_configured = NR }
  in_method && /mRecorder\.setAudioEncoder/ { encoder = NR }
  in_method && /mRecorder\.prepare\(\);/ { prepare = NR }
  in_method && /mRecorder\.start\(\);/ { start = NR }
  in_method && /return true;/ { success = NR }
  in_method && /catch \(IOException e\)/ { io_catch = NR }
  in_method && io_catch && !runtime_catch && /discardFailedRecording\(outputConfigured\);/ { io_cleanup = NR }
  in_method && /catch \(RuntimeException e\)/ { runtime_catch = NR }
  in_method && runtime_catch && /discardFailedRecording\(outputConfigured\);/ { runtime_cleanup = NR }
  in_method && /return false;/ {
    failure = NR
    exit !(initial_release < try_line && try_line < construct && construct < source &&
      source < format && format < output && output < encoder &&
      encoder < output_configured && output_configured < prepare &&
      prepare < start && start < success && success < io_catch &&
      io_catch < io_cleanup && io_cleanup < runtime_catch &&
      runtime_catch < runtime_cleanup && runtime_cleanup < failure)
  }
  END { if (!failure) exit 1 }
' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder construction and configuration must stay inside guarded startup cleanup." >&2
  exit 1
fi

failed_start_call_count=$(grep -Fc "discardFailedRecording(outputConfigured);" "$MAIN_ACTIVITY" || true)
if [ "$failed_start_call_count" -ne 2 ]; then
  printf '%s\n' "Both recorder startup catch paths must discard failed-start output." >&2
  exit 1
fi
if ! awk '
  /private void discardFailedRecording\(boolean outputConfigured\)/ { in_cleanup = 1 }
  in_cleanup && /releaseRecorder\(\);/ { release = NR }
  in_cleanup && /if \(!outputConfigured\)/ { output_guard = NR }
  in_cleanup && /if \(mFileName != null\)/ { file_guard = NR }
  in_cleanup && /File recording = new File\(mFileName\);/ { file = NR }
  in_cleanup && /recording\.exists\(\)/ { exists = NR }
  in_cleanup && /!recording\.delete\(\)/ { delete_file = NR }
  in_cleanup && /failed recording cleanup failed/ { generic_log = NR }
  in_cleanup && /^    }$/ {
    exit !(release && output_guard && file_guard && file && exists && delete_file && generic_log &&
      release < output_guard && output_guard < file_guard && file_guard < file && file < exists &&
      exists <= delete_file && delete_file < generic_log)
  }
  END {
    exit !(release && output_guard && file_guard && file && exists && delete_file && generic_log &&
      release < output_guard && output_guard < file_guard && file_guard < file && file < exists &&
      exists <= delete_file && delete_file < generic_log)
  }
' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Failed recorder startup must release before deleting partial output and log generically." >&2
  exit 1
fi
for sensitive_cleanup_log in \
  'failed recording cleanup failed" +' \
  'Log.e(LOG_TAG, "failed recording cleanup failed",' \
  'Log.e(LOG_TAG, mFileName' \
  'Log.e(LOG_TAG, recording'; do
  if grep -Fq "$sensitive_cleanup_log" "$MAIN_ACTIVITY"; then
    printf '%s\n' "Failed recording cleanup logs must not expose path or exception details." >&2
    exit 1
  fi
done

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

for recorder_error_contract in \
  "mRecorder.setOnErrorListener" \
  "public void onError(MediaRecorder mr, int what, int extra)" \
  "if (mRecorder != mr)" \
  'Log.e(LOG_TAG, "recording error");' \
  "discardFailedRecording(true);" \
  "resetRecordingControls();" \
  "resetPlaybackControls();"; do
  if ! grep -Fq "$recorder_error_contract" "$MAIN_ACTIVITY"; then
    printf '%s\n' "Recorder runtime error callback must keep contract: $recorder_error_contract" >&2
    exit 1
  fi
done
if grep -Eq 'recording error.*(what|extra|mFileName)|Log\.e\([^;]*(what|extra|mFileName)' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder runtime error logs must not expose platform codes or recording paths." >&2
  exit 1
fi
if ! awk '
  /mRecorder\.setAudioEncoder/ { encoder = NR }
  /mRecorder\.setOnErrorListener/ { listener = NR }
  /mRecorder\.prepare\(\);/ { prepare = NR }
  /public void onError\(MediaRecorder mr, int what, int extra\)/ { in_error = 1 }
  in_error && /if \(mRecorder != mr\)/ { guard = NR }
  in_error && guard && /return;/ && !stale_return { stale_return = NR }
  in_error && /Log\.e\(LOG_TAG, "recording error"\);/ { error_log = NR }
  in_error && /discardFailedRecording\(true\);/ { discard = NR }
  in_error && /resetRecordingControls\(\);/ { recording_reset = NR }
  in_error && /resetPlaybackControls\(\);/ { playback_reset = NR; in_error = 0 }
  in_error && /^            \}\);$/ { in_error = 0 }
  END {
    exit !(encoder && listener && prepare && encoder < listener && listener < prepare &&
      guard && stale_return && error_log && discard && recording_reset && playback_reset &&
      guard < stale_return && stale_return < error_log && error_log < discard &&
      discard < recording_reset && recording_reset < playback_reset)
  }
' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder error listener must guard ownership, clean up, and reset controls in order." >&2
  exit 1
fi

player_identity_guard_count=$(grep -Fc "if (mPlayer != mp)" "$MAIN_ACTIVITY" || true)
if [ "$player_identity_guard_count" -ne 2 ]; then
  printf '%s\n' "Playback completion and error callbacks must both guard retained player identity." >&2
  exit 1
fi
if ! awk '
  /public void onCompletion\(MediaPlayer mp\)/ { in_completion = 1 }
  in_completion && /if \(mPlayer != mp\)/ { completion_guard = NR }
  in_completion && completion_guard && /return;/ && !completion_return { completion_return = NR }
  in_completion && /releasePlayer\(\);/ { completion_release = NR }
  in_completion && /resetPlaybackControls\(\);/ { completion_reset = NR; in_completion = 0 }
  /public boolean onError\(MediaPlayer mp, int what, int extra\)/ { in_error = 1 }
  in_error && /if \(mPlayer != mp\)/ { error_guard = NR }
  in_error && error_guard && /return true;/ && !stale_error_return { stale_error_return = NR }
  in_error && /Log\.e\(LOG_TAG, "playback error"\);/ { error_log = NR }
  in_error && /releasePlayer\(\);/ { error_release = NR }
  in_error && /resetPlaybackControls\(\);/ { error_reset = NR }
  in_error && error_reset && /return true;/ { active_error_return = NR; in_error = 0 }
  in_error && /^            \}\);$/ { in_error = 0 }
  END {
    exit !(completion_guard && completion_return && completion_release && completion_reset &&
      completion_guard < completion_return && completion_return < completion_release &&
      completion_release < completion_reset && error_guard && stale_error_return &&
      error_log && error_release && error_reset && active_error_return &&
      error_guard < stale_error_return && stale_error_return < error_log &&
      error_log < error_release && error_release < error_reset &&
      error_reset < active_error_return)
  }
' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Playback callbacks must reject stale players before logging, release, or UI reset." >&2
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

if ! awk '
  /private boolean onRecord\(boolean start\)/ {
    in_on_record = 1
  }
  /private boolean onPlay\(boolean start\)/ {
    in_on_record = 0
  }
  in_on_record && /boolean recorderPresent = mRecorder != null;/ {
    found_active_guard = 1
  }
  in_on_record && found_active_guard && /boolean stopped = stopRecording\(\);/ {
    found_stop = 1
  }
  in_on_record && found_stop && /if \(recorderPresent && !stopped\)/ {
    found_failure_guard = 1
  }
  in_on_record && found_failure_guard && /discardStopFailedRecording\(\);/ {
    found_discard = 1
  }
  in_on_record && found_discard && /return stopped;/ {
    found_return = 1
  }
  END {
    exit found_active_guard && found_stop && found_failure_guard && found_discard && found_return ? 0 : 1
  }
' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Explicit recorder stop must guard, stop, discard failed output, and propagate the result in order." >&2
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

if ! awk '
  /private boolean stopRecording\(\)/ {
    in_stop = 1
  }
  /private void releaseRecorder\(\)/ {
    in_stop = 0
  }
  in_stop && /releaseRecorder\(\);/ {
    found_release = 1
  }
  in_stop && found_release && /return stopped;/ {
    found_return_after_release = 1
  }
  END {
    exit found_release && found_return_after_release ? 0 : 1
  }
' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder finalization must release the recorder before returning its stop result." >&2
  exit 1
fi

if ! awk '
  /private void discardInterruptedRecording\(\)/ {
    in_discard = 1
  }
  in_discard && /stopRecording\(\);/ {
    found_stop = 1
  }
  in_discard && found_stop && /recording\.delete\(\)/ {
    found_delete_after_stop = 1
  }
  in_discard && /interrupted recording cleanup failed/ {
    found_generic_error = 1
  }
  in_discard && /^    }$/ {
    exit found_stop && found_delete_after_stop && found_generic_error ? 0 : 1
  }
  END {
    exit found_stop && found_delete_after_stop && found_generic_error ? 0 : 1
  }
' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Interrupted recordings must stop before deletion and use a generic cleanup error." >&2
  exit 1
fi

if ! awk '
  /private void discardStopFailedRecording\(\)/ {
    in_discard = 1
  }
  in_discard && /mFileName != null/ {
    found_path_guard = 1
  }
  in_discard && found_path_guard && /new File\(mFileName\)/ {
    found_file = 1
  }
  in_discard && found_file && /recording\.exists\(\) && !recording\.delete\(\)/ {
    found_delete = 1
  }
  in_discard && found_delete && /failed finalization cleanup failed/ {
    found_generic_error = 1
  }
  in_discard && /^    }$/ {
    exit found_path_guard && found_file && found_delete && found_generic_error ? 0 : 1
  }
  END {
    exit found_path_guard && found_file && found_delete && found_generic_error ? 0 : 1
  }
' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Failed finalization output cleanup must be guarded, delete the file, and log generically." >&2
  exit 1
fi

if grep -Eq 'Log\.[a-zA-Z]+\([^;]*(mFileName|recording\.get|\.getMessage\(\))' "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder logs must not expose recording paths or exception details." >&2
  exit 1
fi

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
if ! printf '%s\n' "$ON_PAUSE" | grep -Fq "discardInterruptedRecording();"; then
  printf '%s\n' "Recorder lifecycle cleanup must discard interrupted recording after guarded finalization." >&2
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

workflow_paths=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print | LC_ALL=C sort)
if [ "$workflow_paths" != "$CI_WORKFLOW" ]; then
  printf '%s\n' "check.yml must remain the only approved GitHub Actions workflow." >&2
  exit 1
fi

expected_ci_workflow > "$EXPECTED_FILE"
if ! cmp -s "$CI_WORKFLOW" "$EXPECTED_FILE"; then
  printf '%s\n' "GitHub Actions check workflow must match the approved full Android security baseline." >&2
  exit 1
fi

cat > "$EXPECTED_FILE" <<'EOF'
* @garethpaul
/.github/CODEOWNERS @garethpaul
/.github/workflows/ @garethpaul
/Makefile @garethpaul
/scripts/check-baseline.sh @garethpaul
/build.gradle @garethpaul
/settings.gradle @garethpaul
/gradle.properties @garethpaul
/gradle/ @garethpaul
/gradlew @garethpaul
/gradlew.bat @garethpaul
/app/ @garethpaul
EOF
if [ ! -f "$CODEOWNERS" ] || ! cmp -s "$CODEOWNERS" "$EXPECTED_FILE"; then
  printf '%s\n' "CODEOWNERS must protect CI, Gradle, and recorder privacy boundaries." >&2
  exit 1
fi

for make_contract in \
  'override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' \
  'ANDROID_HOME ?=' \
  'ANDROID_SDK_ROOT ?=' \
  'GRADLE ?= $(ROOT)gradlew' \
  'ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))'; do
  if ! grep -Fxq "$make_contract" "$ROOT_DIR/Makefile"; then
    printf '%s\n' "Makefile must keep contract: $make_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc '$(ROOT)scripts/check-baseline.sh' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "Makefile lint must run the baseline checker from the protected root." >&2
  exit 1
fi
if [ "$(grep -Fc 'cd $(ROOT) && ANDROID_HOME=' "$ROOT_DIR/Makefile")" -ne 3 ]; then
  printf '%s\n' "All three Gradle gates must execute from the protected root." >&2
  exit 1
fi
for gradle_contract in \
  '$(GRADLE) lint --no-daemon' \
  '$(GRADLE) test --no-daemon' \
  '$(GRADLE) assembleDebug --no-daemon'; do
  if [ "$(grep -Fc "$gradle_contract" "$ROOT_DIR/Makefile")" -ne 1 ]; then
    printf '%s\n' "Makefile must keep one rooted Gradle contract: $gradle_contract" >&2
    exit 1
  fi
done

if ! grep -Fxq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-14-android-audio-make-root-override-protection.md"; then
  printf '%s\n' "Android audio Make root protection plan must record completed status." >&2
  exit 1
fi

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

if ! grep -Fq "Pause-interrupted recordings are deleted" "$README"; then
  printf '%s\n' "README must document pause-interrupted recording deletion." >&2
  exit 1
fi

if ! grep -Fq "Recorder configuration failures" "$README"; then
  printf '%s\n' "README must document recorder configuration failure handling." >&2
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

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-12-recorder-configuration-failures.md" || \
   ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-12-recorder-configuration-failures.md"; then
  printf '%s\n' "Recorder configuration-failure plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$CI_PLAN" ]; then
  printf '%s\n' "Recorder CI baseline plan is missing." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$CI_PLAN" || \
   ! grep -Fq "build-tools 24.0.3" "$CI_PLAN" || \
   ! grep -Fq 'complete `make check` gate' "$CI_PLAN"; then
  printf '%s\n' "Recorder CI baseline plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$HOSTED_ANDROID_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq "make check" "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq "OldTargetApi" "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq 'GitHub Actions `pull_request` run `27401263032` passed' "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq "97509a11946ed1a846ebf0ab431c9ca8aa9b8d17" "$HOSTED_ANDROID_PLAN"; then
  printf '%s\n' "Hosted recorder verification plan must record completed local and hosted evidence." >&2
  exit 1
fi

if [ ! -f "$WRAPPER_PLAN" ] || \
   ! grep -Fq "status: completed" "$WRAPPER_PLAN" || \
   ! grep -Fq "fresh temporary Gradle user home" "$WRAPPER_PLAN" || \
   ! grep -Fq "incorrect distribution checksum was rejected" "$WRAPPER_PLAN" || \
   ! grep -Fq 'SDK-backed `make check` passed' "$WRAPPER_PLAN" || \
   ! grep -Fq "external working directory" "$WRAPPER_PLAN" || \
   ! grep -Fq "hostile mutations rejected" "$WRAPPER_PLAN" || \
   ! grep -Fq 'pull-request `Check` run `27439366513` passed' "$WRAPPER_PLAN" || \
   ! grep -Fq 'CodeQL run `27439364674` passed' "$WRAPPER_PLAN" || \
   ! grep -Fq "63eca0b1c8f5a921c9810324a9474269e5f83268" "$WRAPPER_PLAN"; then
  printf '%s\n' "Gradle wrapper plan must record completed local verification evidence." >&2
  exit 1
fi

if ! grep -Fq "distributionSha256Sum" "$README" || \
   ! grep -Fq "does not make the first build offline-reproducible" "$README" || \
   ! grep -Fq "wrapper JAR and Gradle distribution checksums" "$SECURITY"; then
  printf '%s\n' "Repository docs must describe wrapper verification and its online boundary." >&2
  exit 1
fi

if ! grep -Fq "canonical GitHub Actions workflow installs Android API 22" "$README" || \
   ! grep -Fq "2026-06-12-hosted-android-verification.md" "$README"; then
  printf '%s\n' "README must document the hosted Android gate and plan." >&2
  exit 1
fi

if [ ! -f "$INTERRUPTED_RECORDING_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$INTERRUPTED_RECORDING_PLAN" || \
   ! grep -Fq "make check" "$INTERRUPTED_RECORDING_PLAN"; then
  printf '%s\n' "Interrupted recording cleanup plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$FAILED_START_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$FAILED_START_PLAN" || \
   ! grep -Fq "make check" "$FAILED_START_PLAN" || \
   ! grep -Fq "hostile mutations" "$FAILED_START_PLAN"; then
  printf '%s\n' "Failed-start recording cleanup plan must record completed verification." >&2
  exit 1
fi

if [ ! -f "$STOP_FAILURE_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$STOP_FAILURE_PLAN" || \
   ! grep -Fq "make check" "$STOP_FAILURE_PLAN" || \
   ! grep -Fq "hostile mutations" "$STOP_FAILURE_PLAN"; then
  printf '%s\n' "Stop-failure recording cleanup plan must record completed verification." >&2
  exit 1
fi

if [ ! -f "$STALE_PLAYER_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$STALE_PLAYER_PLAN" || \
   ! grep -Fq "make check" "$STALE_PLAYER_PLAN" || \
   ! grep -Fq "hostile mutations" "$STALE_PLAYER_PLAN"; then
  printf '%s\n' "Stale player callback plan must record completed verification." >&2
  exit 1
fi

if [ ! -f "$RECORDER_ERROR_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$RECORDER_ERROR_PLAN" || \
   ! grep -Fq "make check" "$RECORDER_ERROR_PLAN" || \
   ! grep -Fq "hostile mutations" "$RECORDER_ERROR_PLAN"; then
  printf '%s\n' "Recorder runtime error plan must record completed verification." >&2
  exit 1
fi

for recorder_error_doc in "$ROOT_DIR/AGENTS.md" "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "MediaRecorder errors" "$recorder_error_doc"; then
    printf '%s\n' "$recorder_error_doc must document active recorder error cleanup." >&2
    exit 1
  fi
done

for stale_player_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "stale MediaPlayer callbacks" "$stale_player_doc"; then
    printf '%s\n' "$stale_player_doc must document retained-player callback ownership." >&2
    exit 1
  fi
done

for stop_failure_doc in "$ROOT_DIR/AGENTS.md" "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Explicit stop failures delete" "$stop_failure_doc"; then
    printf '%s\n' "$stop_failure_doc must document explicit stop-failure output deletion." >&2
    exit 1
  fi
done

for failed_start_doc in "$README" "$SECURITY" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "failed recorder startup" "$failed_start_doc"; then
    printf '%s\n' "$failed_start_doc must document failed recorder startup cleanup." >&2
    exit 1
  fi
done

printf '%s\n' "Audio recorder baseline checks passed."
