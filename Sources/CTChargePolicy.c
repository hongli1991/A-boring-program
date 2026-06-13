#include "CTChargePolicy.h"
#include <CoreFoundation/CoreFoundation.h>
#include <notify.h>

static CFStringRef CTChargeDomain(void) {
    return CFSTR("com.apple.coreduetd.batterysaver");
}

CTStatus CTChargePolicyRead(CTChargePolicy *policy) {
    if (!policy) return CTStatusInvalidArgument;
    policy->enabled = false;
    policy->maxPercent = 80.0f;
    policy->stopWhenPluggedIn = false;

    CFStringRef domain = CTChargeDomain();
    CFTypeRef threshold = CFPreferencesCopyAppValue(CFSTR("autoDisableThreshold"), domain);
    if (threshold && CFGetTypeID(threshold) == CFNumberGetTypeID()) {
        CFNumberGetValue((CFNumberRef)threshold, kCFNumberFloatType, &policy->maxPercent);
        policy->enabled = true;
    }
    if (threshold) CFRelease(threshold);

    Boolean exists = false;
    policy->stopWhenPluggedIn = CFPreferencesGetAppBooleanValue(CFSTR("autoDisableWhenPluggedIn"), domain, &exists);
    return CTStatusOK;
}

CTStatus CTChargePolicyWrite(const CTChargePolicy *policy) {
    if (!policy) return CTStatusInvalidArgument;
    if (policy->maxPercent < 40.0f || policy->maxPercent > 100.0f) return CTStatusInvalidArgument;

    CFStringRef domain = CTChargeDomain();
    if (policy->enabled) {
        CFNumberRef threshold = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &policy->maxPercent);
        if (!threshold) return CTStatusIOError;
        CFPreferencesSetAppValue(CFSTR("autoDisableThreshold"), threshold, domain);
        CFRelease(threshold);
    } else {
        CFPreferencesSetAppValue(CFSTR("autoDisableThreshold"), NULL, domain);
    }
    CFPreferencesSetAppValue(CFSTR("autoDisableWhenPluggedIn"), policy->stopWhenPluggedIn ? kCFBooleanTrue : kCFBooleanFalse, domain);
    if (!CFPreferencesAppSynchronize(domain)) return CTStatusIOError;
    notify_post("com.apple.smartcharging.defaultschanged");
    notify_post("com.apple.powerd.lowpowermode");
    return CTStatusOK;
}
