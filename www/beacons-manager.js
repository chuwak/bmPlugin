      


function BeaconsManager() {
};
if(!window.plugins) {
    window.plugins = {};
}
if (!window.plugins.BeaconsManager) {
    window.plugins.BeaconsManager = new BeaconsManager();
}
BeaconsManager.prototype.startScan = function(successCallback, errorCallback, array) {
    cordova.exec(successCallback, errorCallback, "BeaconsManager", "startScan", array);
};
               
BeaconsManager.prototype.stopScan = function(successCallback, errorCallback) {
   cordova.exec(successCallback, errorCallback, "BeaconsManager", "stopScan", {});
};

module.exports = BeaconsManager;




// exports.on = function (event, callback, scope) {
//     this.core.on(event, callback, scope);
// };

// /**
//  * Unregister callback for given event.
//  *
//  * @param {String} event
//  *      The event's name
//  * @param {Function} callback
//  *      The function to be exec as callback
//  */
// exports.un = function (event, callback) {
//     this.core.un(event, callback, scope);
// };




// /**********
//  * EVENTS *
//  **********/

// /**
//  * Register callback for given event.
//  *
//  * @param {String} event
//  *      The event's name
//  * @param {Function} callback
//  *      The function to be exec as callback
//  * @param {Object?} scope
//  *      The callback function's scope
//  */
// exports.on = function (event, callback, scope) {

//     if (!this._listener[event]) {
//         this._listener[event] = [];
//     }

//     var item = [callback, scope || window];

//     this._listener[event].push(item);
// };

// /**
//  * Unregister callback for given event.
//  *
//  * @param {String} event
//  *      The event's name
//  * @param {Function} callback
//  *      The function to be exec as callback
//  */
// exports.un = function (event, callback) {
//     var listener = this._listener[event];

//     if (!listener)
//         return;

//     for (var i = 0; i < listener.length; i++) {
//         var fn = listener[i][0];

//         if (fn == callback) {
//             listener.splice(i, 1);
//             break;
//         }
//     }
// };


