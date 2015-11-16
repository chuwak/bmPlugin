package com.aaw.beaconsmanager;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.IBinder;
import android.os.RemoteException;
import android.preference.PreferenceManager;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import org.altbeacon.beacon.*;
import org.altbeacon.beacon.simulator.BeaconSimulator;
import org.altbeacon.beacon.startup.BootstrapNotifier;
import org.altbeacon.beacon.startup.RegionBootstrap;
import org.apache.cordova.CordovaInterface;
import org.json.JSONObject;

import java.io.*;
import java.util.*;


public class AltMonitoring  extends Service implements  BeaconConsumer, RangeNotifier {
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
            altBeaconManager.setRegionExitPeriod(8*1000L);

        }catch (Exception e){
            Log.e(TAG, e.getMessage());
        }

    }


    public void start(){
        Log.w(TAG, "=== start ===");

        // all alt beacons parser already parsed

        // kontakt.io
        BeaconManager.getInstanceForApplication(this).getBeaconParsers().add(new BeaconParser().
                setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25"));


        if(isEmulator()) {
            BeaconManager.setBeaconSimulator(new BeaconSimulator() {
                @Override
                public List<Beacon> getBeacons() {
                    ArrayList<Beacon> beacons = new ArrayList<Beacon>();
                    Beacon beacon1 = new AltBeacon.Builder().setId1("DF7E1C79-43E9-44FF-886F-1D1F7DA6997A")
                            .setId2("1").setId3("1").setRssi(-55).setTxPower(-55).build();
                    Beacon beacon2 = new AltBeacon.Builder().setId1("DF7E1C79-43E9-44FF-886F-1D1F7DA6997A")
                            .setId2("1").setId3("2").setRssi(-55).setTxPower(-55).build();
                    Beacon beacon3 = new AltBeacon.Builder().setId1("DF7E1C79-43E9-44FF-886F-1D1F7DA6997A")
                            .setId2("1").setId3("3").setRssi(-55).setTxPower(-55).build();
                    Beacon beacon4 = new AltBeacon.Builder().setId1("DF7E1C79-43E9-44FF-886F-1D1F7DA6997A")
                            .setId2("1").setId3("4").setRssi(-55).setTxPower(-55).build();
                    beacons.add(beacon1);
                    beacons.add(beacon2);
                    beacons.add(beacon3);
                    beacons.add(beacon4);
                    return beacons;
                }
            });
        }


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
        return  getApplicationContext().bindService(intent, connection, mode);
    }
    @Override
    public void unbindService(ServiceConnection connection) {
        Log.w(TAG,"=== Unbind from IBeacon service ===");
        getApplicationContext().unbindService(connection);

    }


    @Override
    public void onDestroy() {
        if(altBeaconManager != null){

            altBeaconManager.unbind(this);
            altBeaconManager = null;
        }
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
                //showNotification("entered allBeaconsRegion.  starting ranging");

            }

            @Override
            public void didExitRegion(Region region) {
                process("exit", region);
                Log.w(TAG, "I no longer see an beacon");
            }

            @Override
            public void didDetermineStateForRegion(int state, Region region) {
                //Log.w(TAG, "RegionBootstrap  I have just switched from seeing/not seeing beacons: "+state);
            }
        });

        try {

            extBeaconsList = this.loadBeacons();
//            for(ExtBeacon eb: extBeaconsList){
//                altBeaconManager.startMonitoringBeaconsInRegion(eb.getRegion());
//
//            }
            // for monitoring all regions
            for(ExtBeacon eb: extBeaconsList){
                altBeaconManager.startMonitoringBeaconsInRegion(eb.getRegion());

            }
           // altBeaconManager.startMonitoringBeaconsInRegion(new Region("all-beacons-allBeaconsRegion", null, null, null));
        } catch (RemoteException e) {
            Log.e(TAG, e.getMessage());
        }


        // === from site
        Region allBeaconsRegion = new Region("all-beacons-region", null, null, null);


        try {
            altBeaconManager.startRangingBeaconsInRegion(allBeaconsRegion);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        altBeaconManager.setRangeNotifier(this);


    }





    //@Override
    public void didRangeBeaconsInRegion(Collection<Beacon> beacons, Region region) {
        for (Beacon beacon: beacons) {
            Log.w(TAG, "===  didRangeBeaconsInRegion ===size:"+beacons.size());
            //showNotification( "===  didRangeBeaconsInRegion ===size: "+beacons.size(), new HashMap<String, String>());

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
        visibleBeacons =  new ArrayList<Beacon>(beacons);
    }


    public static ArrayList<Beacon> getBeacons(){
        // todo fill
        return visibleBeacons;
    }




    public void process(String actionLocationType, Region region){

        ExtBeacon eb = findBeaconInArray(extBeaconsList, region);
        if(eb==null){
            Log.w(TAG, "=== Saved beacon not found ===");
            return;
        }

        Map<String, String> backParams = new HashMap();
        backParams.put("data", eb.getData());
        backParams.put("actionLocationType", actionLocationType);



        switch (eb.getActionType()){
            case 0: break;
            case 1: showNotification(eb.getMsg(), backParams);
        }


    }


    private ExtBeacon findBeaconInArray(ArrayList<ExtBeacon> arr, Region region){
        for(ExtBeacon eb : arr){
            if(eb.getRegion().equals(region)){
                return eb;
            }
        }
        return null;
    }




    private NotificationManager mManager;

    public void showNotification(String notificationStr, Map<String, String> backParam) {
        Log.w(TAG, notificationStr);


        mManager = (NotificationManager) this.getApplicationContext().getSystemService(this.getApplicationContext().NOTIFICATION_SERVICE);


        Intent li = getLaunchAppIntent();
        String launchClassName = li.getComponent().getClassName();
        Class cl = null;
        try {
            cl = Class.forName(launchClassName);
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
            return;
        }
        Intent runAppWithParamsIntent = new Intent(this.getApplicationContext(), cl);
        for(String key: backParam.keySet()){
            runAppWithParamsIntent.putExtra(key, backParam.get(key));
        }
        //runAppWithParamsIntent.putExtra("bmPlugin", "Exist Always");
        //runAppWithParamsIntent.putExtra("backParam", (Serializable) backParam);

        int appIcon =  getAppIcon();
        Notification notification = new Notification( appIcon , notificationStr, System.currentTimeMillis());
        runAppWithParamsIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);

        PendingIntent pendingNotificationIntent = PendingIntent.getActivity(this.getApplicationContext(), 0, runAppWithParamsIntent, PendingIntent.FLAG_UPDATE_CURRENT);

        notification.flags |= Notification.FLAG_AUTO_CANCEL;
        notification.setLatestEventInfo(this.getApplicationContext(), "BeaconsPlugin", notificationStr, pendingNotificationIntent);

        mManager.notify(0, notification);
    }

    public int getAppIcon(){
        PackageManager pm = getPackageManager();

        String pkg = MainApplication.getContext().getPackageName();
        try {
            ApplicationInfo ai = pm.getApplicationInfo(pkg, 0);
            return ai.icon;
            //return iconId;
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }
        return 0;
    }




    private ArrayList<ExtBeacon> loadBeacons(){
        ArrayList<ExtBeacon> extBeaconsList = null;
        sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);
        String beaconsArrString = sharedPreferences.getString("extBeaconsListStr" , "");

        extBeaconsList = (ArrayList<ExtBeacon>) Utils.stringToObject(beaconsArrString);

        for(ExtBeacon eb: extBeaconsList){
            Region currExtBeaconRegion = new Region("region-"+eb.getId(), Identifier.parse(eb.getUuid()), null, null);
            altBeaconManager.getRangedRegions().add(currExtBeaconRegion);
            eb.setRegion(currExtBeaconRegion);
        }
        return extBeaconsList;
    }






     public Intent getLaunchAppIntent(){
         Intent launchIntent = this.getApplicationContext().getPackageManager().getLaunchIntentForPackage(MainApplication.getContext().getPackageName());
         //launchIntent
         return launchIntent;

     }


    public boolean isEmulator(){
        return Build.FINGERPRINT.startsWith("generic");
//        return "google_sdk".equals( Build.PRODUCT );
    }


}
