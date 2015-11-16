    
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
    BeaconsManager.prototype.startScan = function (successCallback, errorCallback, array) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "startScan", [array]);
    };

    BeaconsManager.prototype.stopScan = function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "stopScan", []);
    };

    BeaconsManager.prototype.deviceready = function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "BeaconsManagerPlugin", "deviceready", []);
    };

    module.exports = BeaconsManager;



    channel.deviceready.subscribe(function () {
        // Device is ready now, the listeners are registered
        // and all queued events can be executed.
        cordova.exec(
            function(res){console.log('onDeviceReady successful sent')},
            function(e){alert('error sent onDeviceReady: '+e);},
            'BeaconsManagerPlugin', 'onDeviceReady', []);
    });
