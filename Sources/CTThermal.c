#include "CTThermal.h"
#include <CoreFoundation/CoreFoundation.h>
#include <notify.h>
#include <stdio.h>

#define CT_THERMAL_DISABLED_PLIST "/var/db/com.apple.xpc.launchd/disabled.plist"

static CFMutableDictionaryRef CTThermalCopyDisabledPlist(void) {
    CFURLRef url = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (const UInt8 *)CT_THERMAL_DISABLED_PLIST, sizeof(CT_THERMAL_DISABLED_PLIST) - 1, false);
    if (!url) return CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFDataRef data = NULL;
    SInt32 err = 0;
    Boolean ok = CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, url, &data, NULL, NULL, &err);
    CFRelease(url);
    if (!ok || !data) return CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFPropertyListRef plist = CFPropertyListCreateWithData(kCFAllocatorDefault, data, kCFPropertyListMutableContainersAndLeaves, NULL, NULL);
    CFRelease(data);
    if (!plist || CFGetTypeID(plist) != CFDictionaryGetTypeID()) {
        if (plist) CFRelease(plist);
        return CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return (CFMutableDictionaryRef)plist;
}

bool CTThermalDaemonDisabled(void) {
    CFMutableDictionaryRef dict = CTThermalCopyDisabledPlist();
    if (!dict) return false;
    CFTypeRef value = CFDictionaryGetValue(dict, CFSTR("com.apple.thermalmonitord"));
    bool disabled = value && CFGetTypeID(value) == CFBooleanGetTypeID() && CFBooleanGetValue((CFBooleanRef)value);
    CFRelease(dict);
    return disabled;
}

CTStatus CTThermalSetDaemonDisabled(bool disabled) {
    CFMutableDictionaryRef dict = CTThermalCopyDisabledPlist();
    if (!dict) return CTStatusIOError;
    CFDictionarySetValue(dict, CFSTR("com.apple.thermalmonitord"), disabled ? kCFBooleanTrue : kCFBooleanFalse);

    CFDataRef data = CFPropertyListCreateData(kCFAllocatorDefault, dict, kCFPropertyListXMLFormat_v1_0, 0, NULL);
    CFRelease(dict);
    if (!data) return CTStatusIOError;

    CFURLRef url = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (const UInt8 *)CT_THERMAL_DISABLED_PLIST, sizeof(CT_THERMAL_DISABLED_PLIST) - 1, false);
    if (!url) {
        CFRelease(data);
        return CTStatusIOError;
    }
    SInt32 err = 0;
    Boolean ok = CFURLWriteDataAndPropertiesToResource(url, data, NULL, &err);
    CFRelease(url);
    CFRelease(data);
    if (!ok) return CTStatusPermissionDenied;

    notify_post("com.apple.system.config.network_change");
    notify_post("com.apple.system.timezone");
    return CTStatusOK;
}
