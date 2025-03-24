#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(OukekSpeech, "OukekSpeech",
    CAP_PLUGIN_METHOD(startRecording, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(stopRecording, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(recognize, CAPPluginReturnPromise);
) 