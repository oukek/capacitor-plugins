#import <Capacitor/Capacitor.h>

// Define the plugin
@interface OukekPhoto : CAPPlugin

// Define methods that will be available to JavaScript
- (void)saveImageToAlbum:(CAPPluginCall*)call;

@end 