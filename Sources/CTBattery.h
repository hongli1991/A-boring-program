#ifndef CTBattery_h
#define CTBattery_h

#include "CTStatus.h"
#include <CoreFoundation/CoreFoundation.h>

typedef struct {
    int currentCapacityPercent;
    int rawCurrentCapacityMah;
    int rawMaxCapacityMah;
    int designCapacityMah;
    int cycleCount;
    int voltageMv;
    int amperageMa;
    int temperatureCentiC;
    bool externalConnected;
    bool isCharging;
    char serial[128];
    char manufacturer[128];
    char deviceName[128];
} CTBatteryInfo;

CTStatus CTBatteryRead(CTBatteryInfo *outInfo);
CFDictionaryRef CTBatteryCopyRawDictionary(void);
CFStringRef CTBatteryCreateSummary(const CTBatteryInfo *info);

#endif
