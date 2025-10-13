#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(OukekCalendar, "OukekCalendar",
    CAP_PLUGIN_METHOD(requestPermissions, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(checkPermissions, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getEvents, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(createEvent, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(updateEvent, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(deleteEvent, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getCalendars, CAPPluginReturnPromise);
)