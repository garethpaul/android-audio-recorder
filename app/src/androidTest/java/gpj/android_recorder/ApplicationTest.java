package gpj.android_recorder;

import android.app.Application;
import android.test.ApplicationTestCase;

import java.io.File;
import java.io.FileOutputStream;

/**
 * <a href="http://d.android.com/tools/testing/testing_android.html">Testing Fundamentals</a>
 */
public class ApplicationTest extends ApplicationTestCase<Application> {
    public ApplicationTest() {
        super(Application.class);
    }

    public void testApplicationCreatesRecorderPackage() throws Exception {
        createApplication();

        assertNotNull(getApplication());
        assertEquals("gpj.android_recorder", getApplication().getPackageName());
    }

    public void testFailedRecordingPreservesFinalizedAudio() throws Exception {
        createApplication();
        String fileName = "instrumentation-recording-" + System.nanoTime() + ".3gp";
        RecordingFileStore store = new RecordingFileStore(
                getApplication().getFilesDir(),
                fileName);
        File finalized = null;
        File pending = null;
        try {
            pending = store.beginRecording();
            write(pending, 1);
            assertTrue(store.commitRecording());
            finalized = store.getPlayableFile();
            assertNotNull(finalized);

            pending = store.beginRecording();
            write(pending, 2);
            assertTrue(store.discardRecording());

            assertTrue(finalized.exists());
            assertEquals(1, finalized.length());
            assertFalse(pending.exists());
        } finally {
            store.discardRecording();
            if (finalized != null) {
                finalized.delete();
            }
        }
    }

    private void write(File file, int value) throws Exception {
        FileOutputStream output = new FileOutputStream(file);
        try {
            output.write(value);
        } finally {
            output.close();
        }
    }
}
