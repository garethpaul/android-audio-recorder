package gpj.android_recorder;

import android.app.Application;
import android.test.ApplicationTestCase;

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
}
