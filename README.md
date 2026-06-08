# Android Audio Recorder

Legacy Android sample that records audio to external storage and plays it back.

## Toolchain

This project currently uses the original Android build stack:

- Gradle wrapper 2.2.1
- Android Gradle Plugin 1.2.3
- compile SDK 22 / target SDK 22
- Android build-tools 24.0.3

Configure an Android SDK path before running Gradle:

```sh
export ANDROID_HOME=/path/to/android-sdk
```

or create an untracked `local.properties` file:

```properties
sdk.dir=/path/to/android-sdk
```

## Verify

Run the SDK-free source baseline check first:

```sh
scripts/check-baseline.sh
```

Then run Gradle after Android SDK configuration is available:

```sh
./gradlew lint --no-daemon
./gradlew test --no-daemon
./gradlew assembleDebug --no-daemon
```

If Gradle reports `SDK location not found`, configure `ANDROID_HOME` or
`local.properties` and rerun the command.

The original build-tools 22.0.1 package uses an obsolete `aapt` binary that can
fail to load on current Linux hosts, so this baseline pins build-tools 24.0.3
while leaving the rest of the legacy Android stack unchanged.

## Modernization Notes

The current baseline fixes duplicate playback dispatch from the play button and
keeps Android lint clean for the legacy UI resources. `app/lint.xml` suppresses
only the obsolete lint API database error from this old toolchain and the
missing-density-folder warning for bitmap assets intentionally kept in
`drawable-nodpi`. A future pass should modernize Gradle, SDK levels, runtime
permission handling,
external-storage behavior, and add Android test coverage in an SDK-capable
environment.
