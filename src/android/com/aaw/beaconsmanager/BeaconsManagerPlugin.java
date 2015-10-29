package com.aaw.beaconsmanager;

import android.app.Activity;
import android.preference.PreferenceManager;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import android.content.Context;
import android.content.SharedPreferences;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;

import android.util.Log;
import android.content.Intent;
import org.json.JSONObject;

import java.util.ArrayList;

public class BeaconsManagerPlugin extends CordovaPlugin {
    public static final String TAG = "BeaconsManager";
    public Intent beaconConsumer;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        AltMonitoring.applicationContext = this.cordova.getActivity();//.getApplicationContext();
        beaconConsumer = new Intent(this.cordova.getActivity()/*.getApplicationContext()*/, AltMonitoring.class);
        //beaconConsumer = new AltMonitoring();
    }

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {
        //Log.v(TAG, "execute: data=" + data.toString());

        if (action.equals("startScan")) {
            try {
                JSONArray beaconUUIDs = data.getJSONArray(0);
                this.startMonitoring(beaconUUIDs, callbackContext);
                return true;
            } catch (JSONException e) {
                Log.e(TAG, action + " execute: Got JSON Exception " + e.getMessage());
                callbackContext.error(e.getMessage());
            }
        }

        if (action.equals("stopScan")) {
            try {
                this.stopMonitoring(callbackContext);
                return true;
            } catch (Exception e) {
                Log.e(TAG, action + " execute: Got JSON Exception " + e.getMessage());
                callbackContext.error(e.getMessage());
            }
        }


        if (action.equals("getBeacons")) {
            this.getBeacons(callbackContext);
            return true;
        }

//        if (action.equals("notifyServer")) {
//            this.notifyServer(data.getString(0), data.getInt(1), callbackContext);
//            return true;
//        }
//
//        if (action.equals("notifyServerAuthToken")) {
//            this.notifyServerAuthToken(data.getString(0), callbackContext);
//            return true;
//        }

        return false;
    }

    private void startMonitoring(JSONArray extBeaconsArr, CallbackContext callbackContext) {
       // beaconConsumer.putExtra("beaconUUIDs", beaconUUIDs.toString());
//        SharedPreferences settings = this.cordova.getActivity().getSharedPreferences(AltMonitoring.PREFS_NAME, 0);
//        SharedPreferences.Editor e = settings.edit();
//        e.putString("Beacons", extBeaconsArr.toString());
//        e.commit();

        ArrayList<ExtBeacon> extBeaconsList = new ArrayList();

        try {
            for (int i = 0; i < extBeaconsArr.length(); i++) {
                JSONObject extBcnJso = extBeaconsArr.getJSONObject(i);
                ExtBeacon incBeacon = new ExtBeacon();
                incBeacon.setId(extBcnJso.getInt("id"));
                incBeacon.setUuid(extBcnJso.getString("uuid"));
                incBeacon.setActionType(extBcnJso.getInt("actionType"));
                incBeacon.setData(extBcnJso.getString("data"));
                incBeacon.setMsg(extBcnJso.getString("msg"));

                extBeaconsList.add(incBeacon);
            }
        }catch (Exception e){
            Log.e(TAG, e.getMessage());
        }


        String extBeaconsListStr = Utils.objectToString(extBeaconsList);

        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this.getContext().getApplicationContext());
        SharedPreferences.Editor spe = sharedPreferences.edit();
        spe.putString("extBeaconsListStr", extBeaconsListStr);
        spe.commit();


        this.cordova.getActivity().startService(beaconConsumer);

        callbackContext.success("Service started.");
    }

    private void stopMonitoring(CallbackContext callbackContext) {

        this.cordova.getActivity().stopService(beaconConsumer);
        //beaconConsumer.stop(this.cordova.getActivity());
        callbackContext.success("Service Was stopped");
    }


    private void getBeacons(CallbackContext callbackContext) {
        Log.v(TAG, "GetBeacons start " + callbackContext);
        JSONArray beaconArray = new JSONArray();
        Log.v(TAG, "JSONArray beaconArray " + beaconArray);

        // Can't we get the data from the instance?
        //  Bundle extras = beaconConsumer.getExtras();
//Log.v(TAG, "Bundle extras "+extras);
        try {
            Log.v(TAG, "Start try ");
            //     Hashtable<String, Vector> beacons = (Hashtable) extras.get("beaconUUIDs");
//Log.v(TAG, "Start try "+ beacons);
            // get beacons from static method
//            Hashtable<String, Vector> beacons = AltMonitoring.getBeacons();
////Log.v(TAG, "Start try "+ AttendeaseBeaconConsumer);
//            Enumeration<String> enumKey = beacons.keys();
//            while (enumKey.hasMoreElements()) {
//                String key = enumKey.nextElement();
//                Vector data = beacons.get(key);
//
//                Iterator i = data.iterator();
//                while (i.hasNext()) {
//                    IBeacon beacon = (IBeacon) i.next();
//                    Log.v(TAG, "Hello getBeacons... " + key + " : " + beacon.toString());
//
//                    String proximity = "Unknown";
//
//                    if (beacon.getProximity() == IBeacon.PROXIMITY_FAR) {
//                        proximity = "Far";
//                    } else if (beacon.getProximity() == IBeacon.PROXIMITY_NEAR) {
//                        proximity = "Near";
//                    } else if (beacon.getProximity() == IBeacon.PROXIMITY_IMMEDIATE) {
//                        proximity = "Immediate";
//                    }
//
//                    JSONObject beaconData = new JSONObject();
//                    beaconData.put("uuid", beacon.getProximityUuid());
//                    beaconData.put("major", beacon.getMajor());
//                    beaconData.put("minor", beacon.getMinor());
//                    beaconData.put("proximityString", proximity);
//                    beaconData.put("accuracy", beacon.getAccuracy());
//
//                    beaconArray.put(beaconData);
//                }
//            }

            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, beaconArray));
        } catch (Exception e) {
            Log.e(TAG, "getBeacons: Got Exception " + e.getMessage());
            callbackContext.error(e.getMessage());
        }
    }

//    private void notifyServer(String server, Integer interval, CallbackContext callbackContext) {
//        AttendeaseBeaconConsumer.setNotifyServer(server, interval);
//
//        callbackContext.success("This was a great success...");
//    }
//
//    private void notifyServerAuthToken(String authToken, CallbackContext callbackContext) {
//        Log.v(TAG, "Hello notifyServerAuthToken... " + authToken);
//
//        AttendeaseBeaconConsumer.setNotifyServerAuthToken(authToken);
//
//        //callbackContext.error("This was a big failure...");
//        callbackContext.success("This was a great success...");
//    }



    public Context getContext(){
        return this.cordova.getActivity().getApplicationContext();
    }


    public static final String DATA = "DATA";
    public static final String ACTION = "ACTION";
    public static final String ACTION_FILTER = "com.tenforwardconsulting.cordova.bgloc.ACTION";
    public static final String LOCATION_UPDATE_FILTER = "com.tenforwardconsulting.cordova.bgloc.LOCATION_UPDATE";
    public static final int ACTION_LOCATION_UPDATE = 0;
    public static final int ACTION_STOP_RECORDING = 1;
    public static final int ACTION_START_RECORDING = 2;
    public static final int ACTION_ACTIVITY_KILLED = 3;

    public void onDestroy() {
        Log.d(TAG, "Main Activity destroyed!!!");
        Activity activity = this.cordova.getActivity();

//        if (isEnabled) {
//            if (config.getStopOnTerminate()) {
//                activity.stopService(updateServiceIntent);
//            } else {
                //todo: send info to location service
//                Intent intent = new Intent(/*Constant.ACTION_FILTER*/ "com.aaw.beaconsmanager.AltMonitoring.ACTION");
//                intent.putExtra(ACTION, ACTION_ACTIVITY_KILLED);
//                intent.putExtra(DATA, true);
//                activity.sendBroadcast(intent);
//            }
//        }

        //this.cordova.getActivity().startService(beaconConsumer);
    }

}

