package com.aaw.beaconsmanager;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Environment;
import android.os.IBinder;
import android.os.RemoteException;
import android.preference.PreferenceManager;
import android.util.Log;
import com.apes.appplg2.MainActivity;
import com.apes.appplg2.R;
import org.altbeacon.beacon.*;
import org.altbeacon.beacon.startup.BootstrapNotifier;
import org.altbeacon.beacon.startup.RegionBootstrap;

import java.io.*;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;


public class AltMonitoring  extends Service implements  BeaconConsumer, RangeNotifier/*, BootstrapNotifier*/ {
    protected static final String TAG = "AltMonitoring";


    public static final String PREFS_NAME = "BeaconsStore";

    private static ArrayList<Beacon> visibleBeacons = new ArrayList();

    public static Context applicationContext;

    private BeaconManager altBeaconManager;

    private RegionBootstrap mRegionBootstrap;

    private SharedPreferences sharedPreferences;

    private ArrayList<ExtBeacon> extBeaconsList;



    @Override
    public void onCreate() {
        super.onCreate();
        Log.w(TAG, "=== AltBeacon : onCreate ===");

        try {
            altBeaconManager =  BeaconManager.getInstanceForApplication( this );
            altBeaconManager.setBackgroundMode(true);
            //BeaconManager.setDebug(true);

        }catch (Exception e){
            Log.e(TAG, e.getMessage());
        }

    }


    public void start(){
        Log.w(TAG, "=== start ===");

        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);
        String beaconsArrString = sharedPreferences.getString("extBeaconsListStr" , "");

        extBeaconsList = (ArrayList<ExtBeacon>) Utils.stringToObject(beaconsArrString);

        //SharedPreferences settings = this.getSharedPreferences(AltMonitoring.PREFS_NAME, 0);



        // all alt beacons parser already parsed

        // estimote
        altBeaconManager.getBeaconParsers().add(new BeaconParser().
                        setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25"));


        // kontakt.io
        BeaconManager.getInstanceForApplication(this).getBeaconParsers().add(new BeaconParser().
                setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25"));

        for(ExtBeacon eb: extBeaconsList){
            Region currExtBeaconRegion = new Region("region-"+eb.getId(), Identifier.parse(eb.getUuid()), null, null);
            altBeaconManager.getRangedRegions().add(currExtBeaconRegion);
            eb.setRegion(currExtBeaconRegion);
        }

        //Region mAllBeaconsRegion = new Region("all beacons", null, null, null);

        altBeaconManager.bind(this);


    }

    public void stop(){
        altBeaconManager.unbind(this);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.w(TAG, "=== onStartCommand ===");

        start();
        return  START_STICKY;
        //return START_REDELIVER_INTENT;
    }



    @Override
    public Context getApplicationContext(){
            return MainApplication.getContext();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }



    @Override
    public boolean bindService(Intent intent, ServiceConnection connection, int mode) {
        Log.w(TAG, "=== Bind to IBeacon service ===");
        //Log.w(TAG, altBeaconManager.getBeaconParsers().size()+"");
        return  getApplicationContext().bindService(intent, connection, mode);
    }
    @Override
    public void unbindService(ServiceConnection connection) {
        Log.w(TAG,"=== Unbind from IBeacon service ===");
        getApplicationContext().unbindService(connection);
    }


    @Override
    public void onDestroy() {

        Log.w(TAG, "=== Destroy iBeacon service ===");

    }


    @Override
    public void onBeaconServiceConnect() {
        Log.w(TAG, "=== onBeaconServiceConnect : BeaconConsumer ===");
        altBeaconManager.setMonitorNotifier(new MonitorNotifier() {
            @Override
            public void didEnterRegion(Region region) {
                process("enter", region);
                Log.w(TAG, "I just saw an beacon for the first time!");
                //showNotification("entered region.  starting ranging");
            }

            @Override
            public void didExitRegion(Region region) {
                process("exit", region);
                Log.w(TAG, "I no longer see an beacon");
            }

            @Override
            public void didDetermineStateForRegion(int state, Region region) {
                Log.w(TAG, "RegionBootstrap  I have just switched from seeing/not seeing beacons: "+state);
            }
        });

        try {
            altBeaconManager.startMonitoringBeaconsInRegion(new Region("myMonitoringUniqueId", null, null, null));
        } catch (RemoteException e) {
            Log.e(TAG, e.getMessage());
        }


        // === from site
        Region region = new Region("all-beacons-region", null, null, null);
        try {
            altBeaconManager.startRangingBeaconsInRegion(region);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        altBeaconManager.setRangeNotifier(this);
    }





    //@Override
    public void didRangeBeaconsInRegion(Collection<Beacon> beacons, Region region) {
        for (Beacon beacon: beacons) {
            Log.w(TAG, "===  didRangeBeaconsInRegion ===size:"+beacons.size());
            //if (beacon.getServiceUuid() == 0xfeaa && beacon.getBeaconTypeCode() == 0x00) {
                // This is a Eddystone-UID frame
                Identifier namespaceId = beacon.getId1();
                Identifier instanceId = beacon.getId2();
                Log.d(TAG, "I see a beacon transmitting namespace id: "+namespaceId+
                        " and instance id: "+instanceId+
                        " approximately "+beacon.getDistance()+" meters away.");

                // Do we have telemetry data?
                if (beacon.getExtraDataFields().size() > 0) {
                    long telemetryVersion = beacon.getExtraDataFields().get(0);
                    long batteryMilliVolts = beacon.getExtraDataFields().get(1);
                    long pduCount = beacon.getExtraDataFields().get(3);
                    long uptime = beacon.getExtraDataFields().get(4);

                    Log.d(TAG, "The above beacon is sending telemetry version "+telemetryVersion+
                            ", has been up for : "+uptime+" seconds"+
                            ", has a battery level of "+batteryMilliVolts+" mV"+
                            ", and has transmitted "+pduCount+" advertisements.");

                }
        }
    }


    public static ArrayList<Beacon> getBeacons(){
        // todo fill
        return visibleBeacons;
    }


    //===============================  bootstrap
//
//    //@Override
//    public void didDetermineStateForRegion(int arg0, Region arg1) {
//        Log.w(TAG, "didDetermineStateForRegion region "+arg1);
//
//    }
//
//   // @Override
//    public void didEnterRegion(Region arg0) {
////        if (mMonitoringActivity != null) {
////            mMonitoringActivity.didEnterRegion(arg0);
////        }
////        try {
//            Log.w(TAG, "entered region.  starting ranging");
//        showNotification("entered region.  starting ranging");
////            mBeaconManager.startRangingBeaconsInRegion(mAllBeaconsRegion);
////            mBeaconManager.setRangeNotifier(this);
////        } catch (RemoteException e) {
////            Log.e(TAG, "Cannot start ranging");
////        }
//    }
//
//    //@Override
//    public void didExitRegion(Region arg0) {
////        if (mMonitoringActivity != null) {
////            mMonitoringActivity.didExitRegion(arg0);
////        }
//        Log.w(TAG, "exit region.");
//        showNotification( "exit region.");
//    }
//


    public void process(String actionLocationType, Region region){
        ExtBeacon eb = findBeaconInArray(extBeaconsList, region);
        if(eb==null){
            Log.w(TAG, "=== Saved beacon not found ===");
            return;
        }

        Map backParams = new HashMap();
        backParams.put("data", eb.getData());
        backParams.put("actionLocationType", actionLocationType);



        switch (eb.getActionType()){
            case 0: break;
            case 1: showNotification(eb.getMsg(), backParams);
        }


    }


    private ExtBeacon findBeaconInArray(ArrayList<ExtBeacon> arr, Region region){
        for(ExtBeacon eb : arr){
            if(eb.getRegion() == region){
                return eb;
            }
        }
        return null;
    }




    private NotificationManager mManager;

    public void showNotification(String notificationStr, Map backParam) {
        Log.w(TAG, notificationStr);

        mManager = (NotificationManager) this.getApplicationContext().getSystemService(this.getApplicationContext().NOTIFICATION_SERVICE);
        Intent intent1 = new Intent(this.getApplicationContext(), MainActivity.class);
        intent1.putExtra("backParam", (Serializable) backParam);

        Notification notification = new Notification(R.drawable.ic_launcher, notificationStr, System.currentTimeMillis());
        intent1.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);

        PendingIntent pendingNotificationIntent = PendingIntent.getActivity(this.getApplicationContext(), 0, intent1, PendingIntent.FLAG_UPDATE_CURRENT);
        notification.flags |= Notification.FLAG_AUTO_CANCEL;
        notification.setLatestEventInfo(this.getApplicationContext(), "BeaconsPlugin", notificationStr, pendingNotificationIntent);

        mManager.notify(0, notification);
    }
}
