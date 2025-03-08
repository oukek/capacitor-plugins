#import <Capacitor/Capacitor.h>

// Define the plugin
@interface OukekPay : CAPPlugin

- (void)purchase:(CAPPluginCall *)call;
- (void)getProducts:(CAPPluginCall *)call;
- (void)restorePurchases:(CAPPluginCall *)call;
- (void)addListener:(CAPPluginCall *)call;
- (void)removeAllListeners:(CAPPluginCall *)call;

@end 