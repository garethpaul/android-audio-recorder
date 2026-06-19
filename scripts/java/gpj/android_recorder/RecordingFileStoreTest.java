package gpj.android_recorder;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.attribute.PosixFilePermission;
import java.util.Set;

public final class RecordingFileStoreTest {
    public static void main(String[] args) throws Exception {
        testFailedAttemptPreservesLastRecording();
        testSuccessfulAttemptReplacesLastRecording();
        testRecoveryRestoresBackupAndDeletesPendingOutput();
        testSymlinkCollisionFailsClosed();
        testRecordingFilesAreOwnerOnlyWhenSupported();
    }

    private static void testFailedAttemptPreservesLastRecording() throws Exception {
        File directory = Files.createTempDirectory("recording-store-failed-").toFile();
        try {
            RecordingFileStore store = new RecordingFileStore(directory, "recording.3gp");
            write(store.beginRecording(), "first");
            assertTrue(store.commitRecording(), "initial recording should commit");

            File pending = store.beginRecording();
            write(pending, "partial");
            store.discardRecording();

            assertEquals("first", read(store.getPlayableFile()),
                    "failed recording must preserve the last finalized capture");
            assertFalse(pending.exists(), "failed pending output must be deleted");
        } finally {
            deleteTree(directory);
        }
    }

    private static void testSuccessfulAttemptReplacesLastRecording() throws Exception {
        File directory = Files.createTempDirectory("recording-store-success-").toFile();
        try {
            RecordingFileStore store = new RecordingFileStore(directory, "recording.3gp");
            write(store.beginRecording(), "first");
            assertTrue(store.commitRecording(), "initial recording should commit");

            write(store.beginRecording(), "second");
            assertTrue(store.commitRecording(), "replacement recording should commit");

            assertEquals("second", read(store.getPlayableFile()),
                    "successful recording must replace the previous capture");
            assertFalse(new File(directory, ".recording.3gp.backup").exists(),
                    "successful promotion must remove its rollback backup");
        } finally {
            deleteTree(directory);
        }
    }

    private static void testRecoveryRestoresBackupAndDeletesPendingOutput() throws Exception {
        File directory = Files.createTempDirectory("recording-store-recovery-").toFile();
        try {
            File backup = new File(directory, ".recording.3gp.backup");
            File pending = new File(directory, ".recording.3gp.pending");
            write(backup, "previous");
            write(pending, "interrupted");

            RecordingFileStore store = new RecordingFileStore(directory, "recording.3gp");

            assertEquals("previous", read(store.getPlayableFile()),
                    "startup recovery must restore the last finalized capture");
            assertFalse(backup.exists(), "recovered backup must be consumed");
            assertFalse(pending.exists(), "interrupted pending output must be removed");
        } finally {
            deleteTree(directory);
        }
    }

    private static void testSymlinkCollisionFailsClosed() throws Exception {
        File directory = Files.createTempDirectory("recording-store-symlink-").toFile();
        File outside = File.createTempFile("recording-store-outside-", ".3gp");
        try {
            write(outside, "outside");
            File pending = new File(directory, ".recording.3gp.pending");
            Files.createSymbolicLink(pending.toPath(), outside.toPath());

            boolean rejected = false;
            try {
                new RecordingFileStore(directory, "recording.3gp");
            } catch (IOException expected) {
                rejected = true;
            }

            assertTrue(rejected, "symlinked recorder state must fail closed");
            assertEquals("outside", read(outside),
                    "collision handling must not delete or truncate an external target");
        } finally {
            deleteTree(directory);
            outside.delete();
        }
    }

    private static void testRecordingFilesAreOwnerOnlyWhenSupported() throws Exception {
        File directory = Files.createTempDirectory("recording-store-mode-").toFile();
        try {
            RecordingFileStore store = new RecordingFileStore(directory, "recording.3gp");
            File pending = store.beginRecording();
            Set<PosixFilePermission> permissions = Files.getPosixFilePermissions(pending.toPath());

            assertFalse(permissions.contains(PosixFilePermission.GROUP_READ),
                    "pending output must not be group-readable");
            assertFalse(permissions.contains(PosixFilePermission.OTHERS_READ),
                    "pending output must not be world-readable");
            assertFalse(permissions.contains(PosixFilePermission.GROUP_WRITE),
                    "pending output must not be group-writable");
            assertFalse(permissions.contains(PosixFilePermission.OTHERS_WRITE),
                    "pending output must not be world-writable");
        } catch (UnsupportedOperationException ignored) {
            // Non-POSIX filesystems still exercise File permission calls in production.
        } finally {
            deleteTree(directory);
        }
    }

    private static void write(File file, String value) throws IOException {
        FileOutputStream output = new FileOutputStream(file);
        try {
            output.write(value.getBytes(StandardCharsets.UTF_8));
        } finally {
            output.close();
        }
    }

    private static String read(File file) throws IOException {
        return new String(Files.readAllBytes(file.toPath()), StandardCharsets.UTF_8);
    }

    private static void deleteTree(File file) throws IOException {
        if (file == null || !file.exists()) {
            return;
        }
        if (Files.isSymbolicLink(file.toPath())) {
            Files.delete(file.toPath());
            return;
        }
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteTree(child);
                }
            }
        }
        Files.deleteIfExists(file.toPath());
    }

    private static void assertTrue(boolean value, String message) {
        if (!value) {
            throw new AssertionError(message);
        }
    }

    private static void assertFalse(boolean value, String message) {
        assertTrue(!value, message);
    }

    private static void assertEquals(String expected, String actual, String message) {
        if (!expected.equals(actual)) {
            throw new AssertionError(message + ": expected=" + expected + " actual=" + actual);
        }
    }
}
