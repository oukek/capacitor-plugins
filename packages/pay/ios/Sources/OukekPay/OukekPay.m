#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(OukekPay, "OukekPay",
    CAP_PLUGIN_METHOD(purchase, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getProducts, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(restorePurchases, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(addListener, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(removeAllListeners, CAPPluginReturnPromise);
) 