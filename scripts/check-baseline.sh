#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/gpj/android_recorder/MainActivity.java"
LAYOUT="$ROOT_DIR/app/src/main/res/layout/activity_main.xml"
README="$ROOT_DIR/README.md"
RES_DIR="$ROOT_DIR/app/src/main/res"

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

if ! grep -Fq "onPlay(true);" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play-start branch must call onPlay(true)." >&2
  exit 1
fi

if ! grep -Fq "onPlay(false);" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play-stop branch must call onPlay(false)." >&2
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

if ! grep -Fq "catch (RuntimeException e)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Recorder/player stop and start failures must be guarded." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md is missing." >&2
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

printf '%s\n' "Audio recorder baseline checks passed."
