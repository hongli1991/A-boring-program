#include "CTDisplay.h"
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <dlfcn.h>
#include <notify.h>
#include <string.h>

typedef struct __IOMobileFramebuffer *IOMobileFramebufferRef;

static void CTDisplayCopyPanelId(char *buffer, size_t size) {
    if (!buffer || size == 0) return;
    buffer[0] = 0;
    void *handle = dlopen("/System/Library/PrivateFrameworks/IOMobileFramebuffer.framework/IOMobileFramebuffer", RTLD_LAZY);
    if (!handle) return;

    IOReturn (*GetMainDisplay)(IOMobileFramebufferRef *) = dlsym(handle, "IOMobileFramebufferGetMainDisplay");
    io_service_t (*GetServiceObject)(IOMobileFramebufferRef) = dlsym(handle, "IOMobileFramebufferGetServiceObject");
    if (!GetMainDisplay || !GetServiceObject) return;

    IOMobileFramebufferRef fb = NULL;
    if (GetMainDisplay(&fb) != kIOReturnSuccess || !fb) return;
    io_service_t service = GetServiceObject(fb);
    if (!service) return;

    CFTypeRef value = IORegistryEntryCreateCFProperty(service, CFSTR("Panel_ID"), kCFAllocatorDefault, 0);
    if (value) {
        if (CFGetTypeID(value) == CFStringGetTypeID()) {
            CFStringGetCString((CFStringRef)value, buffer, size, kCFStringEncodingUTF8);
        } else {
            CFStringRef desc = CFCopyDescription(value);
            if (desc) {
                CFStringGetCString(desc, buffer, size, kCFStringEncodingUTF8);
                CFRelease(desc);
            }
        }
        CFRelease(value);
    }
}

CTStatus CTDisplayRead(CTDisplayInfo *info) {
    if (!info) return CTStatusInvalidArgument;
    memset(info, 0, sizeof(*info));
    info->preferredMaxFps = 60;
    info->currentMaxFps = 60;

    CFTypeRef stored = CFPreferencesCopyAppValue(CFSTR("MaxFPS"), CFSTR("com.codex.control.display"));
    if (stored && CFGetTypeID(stored) == CFNumberGetTypeID()) {
        CFNumberGetValue((CFNumberRef)stored, kCFNumberIntType, &info->preferredMaxFps);
    }
    if (stored) CFRelease(stored);
    info->unlock48Enabled = CFPreferencesGetAppBooleanValue(CFSTR("Unlock48FPS"), CFSTR("com.codex.control.display"), NULL);
    CTDisplayCopyPanelId(info->panelId, sizeof(info->panelId));
    return CTStatusOK;
}

CTStatus CTDisplaySetPreferredMaxFPS(int fps) {
    if (fps != 30 && fps != 60 && fps != 80 && fps != 90 && fps != 120) return CTStatusInvalidArgument;
    CFNumberRef value = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
    if (!value) return CTStatusIOError;
    CFPreferencesSetAppValue(CFSTR("MaxFPS"), value, CFSTR("com.codex.control.display"));
    CFRelease(value);
    if (!CFPreferencesAppSynchronize(CFSTR("com.codex.control.display"))) return CTStatusIOError;
    return CTStatusOK;
}

static void CTDisplaySetDomainBool(CFStringRef domain, CFStringRef key, bool enabled) {
    CFPreferencesSetAppValue(key, enabled ? kCFBooleanTrue : kCFBooleanFalse, domain);
    CFPreferencesAppSynchronize(domain);
}

static void CTDisplaySetDomainInt(CFStringRef domain, CFStringRef key, int value) {
    CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &value);
    if (!number) return;
    CFPreferencesSetAppValue(key, number, domain);
    CFRelease(number);
    CFPreferencesAppSynchronize(domain);
}

CTStatus CTDisplaySetUnlock48FPS(bool enabled) {
    CFPreferencesSetAppValue(CFSTR("Unlock48FPS"), enabled ? kCFBooleanTrue : kCFBooleanFalse, CFSTR("com.codex.control.display"));
    CFPreferencesAppSynchronize(CFSTR("com.codex.control.display"));

    /*
     * There is no public global "unlock 48 FPS" API. Old-device 48 FPS caps are
     * commonly caused by thermal/display policy, so this writes the known app
     * frame-duration escape hatch plus display-service preference hints.
     */
    CTDisplaySetDomainBool(CFSTR("com.apple.coreanimation"), CFSTR("CADisableMinimumFrameDurationOnPhone"), enabled);
    CTDisplaySetDomainBool(CFSTR("com.apple.coreanimation"), CFSTR("CAHighFrameRateEnabled"), enabled);
    CTDisplaySetDomainBool(CFSTR("com.apple.backboardd"), CFSTR("DisableMinimumFrameDurationOnPhone"), enabled);
    CTDisplaySetDomainBool(CFSTR("com.apple.springboard"), CFSTR("DisableMinimumFrameDurationOnPhone"), enabled);
    CTDisplaySetDomainInt(CFSTR("com.apple.backboardd"), CFSTR("PreferredFramesPerSecond"), enabled ? 60 : 0);
    CTDisplaySetDomainInt(CFSTR("com.apple.springboard"), CFSTR("PreferredFramesPerSecond"), enabled ? 60 : 0);

    notify_post("com.apple.coreanimation.preferences.changed");
    notify_post("com.apple.springboard.displaychanged");
    notify_post("com.apple.backboardd.displaychanged");
    return CTStatusOK;
}
