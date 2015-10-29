package com.aaw.beaconsmanager;

import android.app.Application;
import android.content.Context;

public class MainApplication extends Application {

    private static Context sContext;

    @Override
    public void onCreate() {
        super.onCreate();

        sContext = getApplicationContext();

        //startService(new Intent(this, AltMonitoring.class));
    }

    public static Context getContext() {
        return sContext;
    }
}
