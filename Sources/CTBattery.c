#include "CTBattery.h"
#include <IOKit/IOKitLib.h>
#include <string.h>

static io_registry_entry_t CTBatteryService(void) {
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSmartBattery"));
    if (service) return service;
    return IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
}

static int CTDictInt(CFDictionaryRef dict, CFStringRef key, int fallback) {
    if (!dict) return fallback;
    CFTypeRef value = CFDictionaryGetValue(dict, key);
    if (!value || CFGetTypeID(value) != CFNumberGetTypeID()) return fallback;
    int result = fallback;
    CFNumberGetValue((CFNumberRef)value, kCFNumberIntType, &result);
    return result;
}

static bool CTDictBool(CFDictionaryRef dict, CFStringRef key, bool fallback) {
    if (!dict) return fallback;
    CFTypeRef value = CFDictionaryGetValue(dict, key);
    if (!value) return fallback;
    if (CFGetTypeID(value) == CFBooleanGetTypeID()) return CFBooleanGetValue((CFBooleanRef)value);
    if (CFGetTypeID(value) == CFNumberGetTypeID()) {
        int result = fallback ? 1 : 0;
        CFNumberGetValue((CFNumberRef)value, kCFNumberIntType, &result);
        return result != 0;
    }
    return fallback;
}

static void CTDictCString(CFDictionaryRef dict, CFStringRef key, char *buffer, size_t bufferSize) {
    if (!buffer || bufferSize == 0) return;
    buffer[0] = 0;
    CFTypeRef value = dict ? CFDictionaryGetValue(dict, key) : NULL;
    if (!value) return;
    if (CFGetTypeID(value) == CFStringGetTypeID()) {
        CFStringGetCString((CFStringRef)value, buffer, bufferSize, kCFStringEncodingUTF8);
    } else {
        CFStringRef description = CFCopyDescription(value);
        if (description) {
            CFStringGetCString(description, buffer, bufferSize, kCFStringEncodingUTF8);
            CFRelease(description);
        }
    }
}

CFDictionaryRef CTBatteryCopyRawDictionary(void) {
    io_registry_entry_t service = CTBatteryService();
    if (!service) return NULL;
    CFMutableDictionaryRef props = NULL;
    kern_return_t kr = IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0);
    IOObjectRelease(service);
    if (kr != KERN_SUCCESS || !props) return NULL;
    return props;
}

CTStatus CTBatteryRead(CTBatteryInfo *outInfo) {
    if (!outInfo) return CTStatusInvalidArgument;
    memset(outInfo, 0, sizeof(*outInfo));

    CFDictionaryRef dict = CTBatteryCopyRawDictionary();
    if (!dict) return CTStatusUnsupported;

    outInfo->currentCapacityPercent = CTDictInt(dict, CFSTR("CurrentCapacity"), -1);
    outInfo->rawCurrentCapacityMah = CTDictInt(dict, CFSTR("AppleRawCurrentCapacity"), -1);
    outInfo->rawMaxCapacityMah = CTDictInt(dict, CFSTR("AppleRawMaxCapacity"), -1);
    outInfo->designCapacityMah = CTDictInt(dict, CFSTR("DesignCapacity"), -1);
    outInfo->cycleCount = CTDictInt(dict, CFSTR("CycleCount"), -1);
    outInfo->voltageMv = CTDictInt(dict, CFSTR("Voltage"), -1);
    outInfo->amperageMa = CTDictInt(dict, CFSTR("Amperage"), -1);
    outInfo->temperatureCentiC = CTDictInt(dict, CFSTR("Temperature"), -1);
    outInfo->externalConnected = CTDictBool(dict, CFSTR("ExternalConnected"), false) ||
                                 CTDictBool(dict, CFSTR("AppleRawExternalConnected"), false);
    outInfo->isCharging = CTDictBool(dict, CFSTR("IsCharging"), false) ||
                          CTDictBool(dict, CFSTR("Charging"), false);
    CTDictCString(dict, CFSTR("Serial"), outInfo->serial, sizeof(outInfo->serial));
    CTDictCString(dict, CFSTR("Manufacturer"), outInfo->manufacturer, sizeof(outInfo->manufacturer));
    CTDictCString(dict, CFSTR("DeviceName"), outInfo->deviceName, sizeof(outInfo->deviceName));

    CFRelease(dict);
    return CTStatusOK;
}

CFStringRef CTBatteryCreateSummary(const CTBatteryInfo *info) {
    if (!info) return CFSTR("{}");
    return CFStringCreateWithFormat(kCFAllocatorDefault, NULL,
        CFSTR("{\"percent\":%d,\"rawCurrentMah\":%d,\"rawMaxMah\":%d,\"designMah\":%d,"
              "\"cycles\":%d,\"voltageMv\":%d,\"amperageMa\":%d,\"temperatureC\":%.2f,"
              "\"externalConnected\":%s,\"charging\":%s,\"serial\":\"%s\",\"manufacturer\":\"%s\",\"deviceName\":\"%s\"}"),
        info->currentCapacityPercent,
        info->rawCurrentCapacityMah,
        info->rawMaxCapacityMah,
        info->designCapacityMah,
        info->cycleCount,
        info->voltageMv,
        info->amperageMa,
        info->temperatureCentiC >= 0 ? (double)info->temperatureCentiC / 100.0 : -1.0,
        info->externalConnected ? "true" : "false",
        info->isCharging ? "true" : "false",
        info->serial,
        info->manufacturer,
        info->deviceName);
}
