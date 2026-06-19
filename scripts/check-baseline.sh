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
OUTPUT_OWNERSHIP_PLAN="$ROOT_DIR/docs/plans/2026-06-14-recorder-output-ownership-boundary.md"
DEVICE_VERIFICATION_PLAN="$ROOT_DIR/docs/plans/2026-06-14-recorder-device-verification-checklist.md"
PLAYBACK_START_FAILURE_PLAN="$ROOT_DIR/docs/plans/2026-06-14-playback-start-failure-controls.md"
PLAYBACK_START_OWNERSHIP_PLAN="$ROOT_DIR/docs/plans/2026-06-14-playback-start-player-ownership.md"
INSTRUMENTATION_BOOTSTRAP_PLAN="$ROOT_DIR/docs/plans/2026-06-14-instrumentation-application-bootstrap.md"
INSTRUMENTATION_GATE_PLAN="$ROOT_DIR/docs/plans/2026-06-15-instrumentation-compilation-gate.md"
RECORDER_START_OWNERSHIP_PLAN="$ROOT_DIR/docs/plans/2026-06-15-recorder-start-ownership.md"
LAUNCHER_EXPORT_PLAN="$ROOT_DIR/docs/plans/2026-06-15-explicit-launcher-export.md"
APPLICATION_TEST="$ROOT_DIR/app/src/androidTest/java/gpj/android_recorder/ApplicationTest.java"
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

for required_path in \
  "$ROOT_DIR/DEVICE_VERIFICATION.md" \
  "$DEVICE_VERIFICATION_PLAN" \
  "$PLAYBACK_START_FAILURE_PLAN" \
  "$PLAYBACK_START_OWNERSHIP_PLAN" \
  "$INSTRUMENTATION_GATE_PLAN"; do
  if [ ! -f "$required_path" ]; then
    printf '%s\n' "Required file is missing: ${required_path#"$ROOT_DIR/"}" >&2
    exit 1
  fi
done

for device_contract in \
  'commit SHA and pull request' \
  'Microphone unavailable' \
  'Prepare/start failure' \
  'Pause during recording' \
  'Stale player callback' \
  'Recorder runtime error' \
  'Process recreation' \
  'Do not convert `not run` into passing evidence.' \
  'recording paths, audio contents' \
  'every recorder device and media row as' \
  'unexecuted'; do
  if ! grep -Fq "$device_contract" "$ROOT_DIR/DEVICE_VERIFICATION.md"; then
    printf '%s\n' "Recorder device checklist must keep contract: $device_contract" >&2
    exit 1
  fi
done

if ! grep -Fq 'DEVICE_VERIFICATION.md' "$README" || \
   ! grep -Fq 'explicit unexecuted rows' "$README" || \
   ! grep -Fqi 'recorder device verification matrix' "$ROOT_DIR/VISION.md" || \
   ! grep -Fq 'every runtime row explicitly unexecuted' "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' 'Repository guidance must document the unexecuted recorder device matrix.' >&2
  exit 1
fi

for plan_contract in \
  'Status: Completed' \
  'make check' \
  'hostile mutations' \
  'No Android SDK, emulator, physical-device, microphone, or media scenario was executed'; do
  if ! grep -Fq "$plan_contract" "$DEVICE_VERIFICATION_PLAN"; then
    printf '%s\n' "Recorder device plan must keep completion evidence: $plan_contract" >&2
    exit 1
  fi
done

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
            android:exported="true"
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

"$ROOT_DIR/scripts/test-recording-file-store.sh"
"$ROOT_DIR/scripts/test-main-activity-contracts.py"

if grep -Fq "getExternalFilesDir" "$MAIN_ACTIVITY" || \
   grep -Fq "Environment.getExternalStorageDirectory" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Microphone recordings must remain in app-internal storage." >&2
  exit 1
fi

if ! grep -Fq 'android:exported="true"' "$MANIFEST" || \
   [ "$(grep -Fc 'android:exported="true"' "$MANIFEST")" -ne 1 ]; then
  printf '%s\n' "Only the launcher activity may retain an explicit exported boundary." >&2
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
  '$(GRADLE) test assembleDebugAndroidTest --no-daemon' \
  '$(GRADLE) assembleDebug --no-daemon'; do
  if [ "$(grep -Fc "$gradle_contract" "$ROOT_DIR/Makefile")" -ne 1 ]; then
    printf '%s\n' "Makefile must keep one rooted Gradle contract: $gradle_contract" >&2
    exit 1
  fi
done
if grep -Fq '$(GRADLE) test --no-daemon' "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile tests must not omit instrumentation APK compilation." >&2
  exit 1
fi

if ! grep -Fxq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-14-android-audio-make-root-override-protection.md"; then
  printf '%s\n' "Android audio Make root protection plan must record completed status." >&2
  exit 1
fi

for instrumentation_contract in \
  "public void testApplicationCreatesRecorderPackage() throws Exception" \
  "createApplication();" \
  "assertNotNull(getApplication());" \
  'assertEquals("gpj.android_recorder", getApplication().getPackageName());'; do
  if ! grep -Fq "$instrumentation_contract" "$APPLICATION_TEST"; then
    printf '%s\n' "ApplicationTest must keep bootstrap assertion: $instrumentation_contract" >&2
    exit 1
  fi
done

for instrumentation_doc_contract in \
  "$README|instrumentation bootstrap creates the application" \
  "$ROOT_DIR/VISION.md|instrumentation bootstrap assertion" \
  "$ROOT_DIR/CHANGES.md|instrumentation bootstrap assertion"; do
  instrumentation_doc=${instrumentation_doc_contract%%|*}
  instrumentation_text=${instrumentation_doc_contract#*|}
  if ! grep -Fq "$instrumentation_text" "$instrumentation_doc"; then
    printf '%s\n' "$instrumentation_doc must document the instrumentation bootstrap assertion." >&2
    exit 1
  fi
done

for instrumentation_plan_contract in \
  "status: completed" \
  "make check" \
  "hostile mutations" \
  "No emulator or physical-device instrumentation was executed"; do
  if ! grep -Fqi "$instrumentation_plan_contract" "$INSTRUMENTATION_BOOTSTRAP_PLAN"; then
    printf '%s\n' "Instrumentation plan must keep completion evidence: $instrumentation_plan_contract" >&2
    exit 1
  fi
done

for instrumentation_gate_doc_contract in \
  "$README|canonical test gate compiles the debug instrumentation APK" \
  "$SECURITY|canonical SDK-backed check compiles instrumentation source" \
  "$ROOT_DIR/CHANGES.md|Added instrumentation APK compilation to the canonical test gate"; do
  instrumentation_gate_doc=${instrumentation_gate_doc_contract%%|*}
  instrumentation_gate_text=${instrumentation_gate_doc_contract#*|}
  if ! grep -Fq "$instrumentation_gate_text" "$instrumentation_gate_doc"; then
    printf '%s\n' "$instrumentation_gate_doc must document canonical instrumentation compilation." >&2
    exit 1
  fi
done

for instrumentation_gate_plan_contract in \
  "Status: Completed" \
  "make check" \
  "hostile mutations" \
  "No emulator or physical-device instrumentation was executed"; do
  if ! grep -Fqi "$instrumentation_gate_plan_contract" "$INSTRUMENTATION_GATE_PLAN"; then
    printf '%s\n' "Instrumentation compilation plan must keep completion evidence: $instrumentation_gate_plan_contract" >&2
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

if ! grep -Fq "./gradlew test assembleDebugAndroidTest --no-daemon" "$README"; then
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

if ! grep -Fqi "recorder finalization failures" "$README"; then
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

if [ ! -f "$OUTPUT_OWNERSHIP_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$OUTPUT_OWNERSHIP_PLAN" || \
   ! grep -Fq "make check" "$OUTPUT_OWNERSHIP_PLAN" || \
   ! grep -Fq "hostile mutations" "$OUTPUT_OWNERSHIP_PLAN"; then
  printf '%s\n' "Recorder output ownership plan must record completed verification." >&2
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

for output_ownership_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fqi "pending" "$output_ownership_doc" || \
     ! grep -Fqi "finalized" "$output_ownership_doc"; then
    printf '%s\n' "$output_ownership_doc must document the recorder output ownership boundary." >&2
    exit 1
  fi
done

printf '%s\n' "Audio recorder baseline checks passed."
