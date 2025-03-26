#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(OukekUpdater, "OukekUpdater",
    CAP_PLUGIN_METHOD(getCurrentVersion, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getStoreVersion, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(openAppStore, CAPPluginReturnPromise);
)