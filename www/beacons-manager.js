
    var exec    = require('cordova/exec'),
    channel = require('cordova/channel');

    function BeaconsManager() {
    };
    if (!window.plugins) {
        window.plugins = {};
    }
    if (!window.plugins.BeaconsManager) {
        window.plugins.BeaconsManager = new BeaconsManager();
    }


    //=================   SERVICE  ===================

    BeaconsManager.prototype.startService = function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "startService", []);
    };

    BeaconsManager.prototype.stopService = function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "stopService", []);
    };


    //=================   MONITORING  ===================


    BeaconsManager.prototype.startMonitoring = function (successCallback, errorCallback, array) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "startMonitoring", [array]);
    };

    BeaconsManager.prototype.stopMonitoring = function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "stopMonitoring", []);
    };

    //===================   RANGING   ====================

    BeaconsManager.prototype.setRangingFunction = function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "setRangingFunction", []);
    };

    BeaconsManager.prototype.startRanging = function (successCallback, errorCallback, array, callbackFunction) {
        this.setRangingFunction(callbackFunction, errorCallback);
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "startRanging", [array]);
    };

    BeaconsManager.prototype.stopRanging = function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "stopRanging", []);
    };

    //=====
    BeaconsManager.prototype.applyParameters = function (successCallback, errorCallback, params) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "applyParameters", [params]);
    };

   
    BeaconsManager.prototype.setMonitoringFunction = function(func){
        //monitoringAsyncFunc = func;
        cordova.exec(
            func,//function(res){},
            function(e){alert('error sent onDeviceReady: '+e);},
            'BeaconsManagerPlugin', 'setMonitoringFunction', []);
    };



    //====================   BLUETOOTH   ===================
    BeaconsManager.prototype.isBluetoothEnabled = function (successCallback, errorCallback, params) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "isBluetoothEnabled", [params]);
    };

    BeaconsManager.prototype.enableBluetooth = function (successCallback, errorCallback, params) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "enableBluetooth", [params]);
    };




    channel.deviceready.subscribe(function () {
        cordova.exec(
            function(res){console.log('deviceReady for plugin called')},
            function(e){console.error('error sent onDeviceReady: '+e);},
            'BeaconsManagerPlugin', 'onDeviceReady', []);
    });

    channel.pause.subscribe(function () {
        cordova.exec(
            function(res){console.log('pause called')},
            function(e){console.error('error pause: '+e);},
            'BeaconsManagerPlugin', 'applyParameters', [{paused:true}]);
    });
    channel.resume.subscribe(function () {
        cordova.exec(
            function(res){console.log('resume called')},
            function(e){console.error('error resume: '+e);},
            'BeaconsManagerPlugin', 'applyParameters', [{paused:false}]);
    });




    module.exports = BeaconsManager;


