#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(OukekClipboard, "OukekClipboard",
    CAP_PLUGIN_METHOD(getChangeCount, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(read, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(write, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(clear, CAPPluginReturnPromise);
)