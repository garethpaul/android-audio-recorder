package gpj.android_recorder;

import java.io.File;
import java.io.IOException;

final class RecordingFileStore {
    private final File directory;
    private final File recordingFile;
    private final File pendingFile;
    private final File backupFile;
    private boolean recordingPending;

    RecordingFileStore(File directory, String recordingFileName) throws IOException {
        if (directory == null || recordingFileName == null ||
                recordingFileName.length() == 0 ||
                recordingFileName.indexOf('/') >= 0 ||
                recordingFileName.indexOf('\\') >= 0) {
            throw new IOException("invalid recording storage");
        }

        this.directory = directory.getCanonicalFile();
        if (!this.directory.isDirectory()) {
            throw new IOException("recording directory unavailable");
        }

        recordingFile = ownedFile(recordingFileName);
        pendingFile = ownedFile("." + recordingFileName + ".pending");
        backupFile = ownedFile("." + recordingFileName + ".backup");
        recoverInterruptedPromotion();
    }

    File beginRecording() throws IOException {
        recoverInterruptedPromotion();
        if (!pendingFile.createNewFile()) {
            throw new IOException("recording output collision");
        }
        if (!protectOwnerOnly(pendingFile)) {
            pendingFile.delete();
            throw new IOException("recording output permissions unavailable");
        }
        recordingPending = true;
        return pendingFile;
    }

    boolean commitRecording() {
        if (!recordingPending || !isOwnedNonEmptyRegularFile(pendingFile)) {
            discardRecording();
            return false;
        }

        recordingPending = false;
        boolean hadRecording = recordingFile.exists();
        if (hadRecording && !isOwnedRegularFile(recordingFile)) {
            discardOwnedFile(pendingFile);
            return false;
        }
        if (backupFile.exists()) {
            discardOwnedFile(pendingFile);
            return false;
        }
        if (hadRecording && !recordingFile.renameTo(backupFile)) {
            discardOwnedFile(pendingFile);
            return false;
        }
        if (!pendingFile.renameTo(recordingFile)) {
            if (hadRecording) {
                backupFile.renameTo(recordingFile);
            }
            discardOwnedFile(pendingFile);
            return false;
        }

        protectOwnerOnly(recordingFile);
        if (hadRecording) {
            discardOwnedFile(backupFile);
        }
        return true;
    }

    boolean discardRecording() {
        recordingPending = false;
        return !pendingFile.exists() || discardOwnedFile(pendingFile);
    }

    File getPlayableFile() {
        return isOwnedNonEmptyRegularFile(recordingFile) ? recordingFile : null;
    }

    boolean hasPlayableRecording() {
        return getPlayableFile() != null;
    }

    private void recoverInterruptedPromotion() throws IOException {
        rejectUnsafeExistingPath(recordingFile);
        rejectUnsafeExistingPath(pendingFile);
        rejectUnsafeExistingPath(backupFile);

        if (!recordingFile.exists() && backupFile.exists() &&
                !backupFile.renameTo(recordingFile)) {
            throw new IOException("recording backup recovery failed");
        }
        if (recordingFile.exists() && backupFile.exists() &&
                !discardOwnedFile(backupFile)) {
            throw new IOException("recording backup cleanup failed");
        }
        if (pendingFile.exists() && !discardOwnedFile(pendingFile)) {
            throw new IOException("recording pending cleanup failed");
        }
        recordingPending = false;
    }

    private File ownedFile(String name) throws IOException {
        File file = new File(directory, name).getAbsoluteFile();
        if (!directory.equals(file.getParentFile()) ||
                !file.equals(file.getCanonicalFile())) {
            throw new IOException("recording path escaped storage");
        }
        return file;
    }

    private void rejectUnsafeExistingPath(File file) throws IOException {
        if (!file.exists()) {
            return;
        }
        if (!file.equals(file.getCanonicalFile()) || !file.isFile()) {
            throw new IOException("unsafe recording path");
        }
    }

    private boolean isOwnedRegularFile(File file) {
        try {
            return file.exists() && file.isFile() &&
                    directory.equals(file.getCanonicalFile().getParentFile()) &&
                    file.equals(file.getCanonicalFile());
        } catch (IOException e) {
            return false;
        }
    }

    private boolean isOwnedNonEmptyRegularFile(File file) {
        return isOwnedRegularFile(file) && file.length() > 0;
    }

    private boolean discardOwnedFile(File file) {
        if (!isOwnedRegularFile(file)) {
            return !file.exists();
        }
        return file.delete();
    }

    private boolean protectOwnerOnly(File file) {
        return file.setReadable(false, false) &&
                file.setWritable(false, false) &&
                file.setExecutable(false, false) &&
                file.setReadable(true, true) &&
                file.setWritable(true, true);
    }
}
