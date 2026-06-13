#include "../Sources/CTBattery.h"
#include "../Sources/CTChargePolicy.h"
#include "../Sources/CTCPU.h"
#include "../Sources/CTDisplay.h"
#include "../Sources/CTThermal.h"
#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void print_cfstring(CFStringRef str) {
    if (!str) return;
    char buffer[4096];
    if (CFStringGetCString(str, buffer, sizeof(buffer), kCFStringEncodingUTF8)) {
        puts(buffer);
    }
}

static int cmd_battery(void) {
    CTBatteryInfo info;
    CTStatus status = CTBatteryRead(&info);
    if (status != CTStatusOK) {
        fprintf(stderr, "%s\n", CTStatusDescription(status));
        return (int)status;
    }
    CFStringRef summary = CTBatteryCreateSummary(&info);
    print_cfstring(summary);
    if (summary) CFRelease(summary);
    return 0;
}

static int cmd_charge(int argc, char **argv) {
    if (argc < 4) {
        fprintf(stderr, "usage: control-helper charge <on|off> <percent>\n");
        return CTStatusInvalidArgument;
    }
    CTChargePolicy policy;
    policy.enabled = strcmp(argv[2], "on") == 0;
    policy.maxPercent = (float)atof(argv[3]);
    policy.stopWhenPluggedIn = true;
    CTStatus status = CTChargePolicyWrite(&policy);
    if (status != CTStatusOK) fprintf(stderr, "%s\n", CTStatusDescription(status));
    return (int)status;
}

static int cmd_cpu(int argc, char **argv) {
    if (argc == 2) {
        CTCPUInfo info;
        CTStatus status = CTCPURead(&info);
        printf("{\"currentHz\":%llu,\"maxHz\":%llu,\"minHz\":%llu,\"note\":\"%s\"}\n",
               info.currentHz, info.maxHz, info.minHz, info.note);
        return (int)status;
    }
    uint64_t hz = strtoull(argv[2], NULL, 10);
    CTStatus status = CTCPUSetMaxHz(hz);
    if (status != CTStatusOK) fprintf(stderr, "%s\n", CTStatusDescription(status));
    return (int)status;
}

static int cmd_display(int argc, char **argv) {
    if (argc < 3) {
        CTDisplayInfo info;
        CTStatus status = CTDisplayRead(&info);
        printf("{\"preferredMaxFps\":%d,\"panelId\":\"%s\"}\n", info.preferredMaxFps, info.panelId);
        return (int)status;
    }
    CTStatus status = CTDisplaySetPreferredMaxFPS(atoi(argv[2]));
    if (status != CTStatusOK) fprintf(stderr, "%s\n", CTStatusDescription(status));
    return (int)status;
}

static int cmd_thermal(int argc, char **argv) {
    if (argc < 3) {
        printf("{\"thermalmonitordDisabled\":%s}\n", CTThermalDaemonDisabled() ? "true" : "false");
        return 0;
    }
    CTStatus status = CTThermalSetDaemonDisabled(strcmp(argv[2], "off") == 0);
    if (status != CTStatusOK) fprintf(stderr, "%s\n", CTStatusDescription(status));
    return (int)status;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: control-helper <battery|charge|cpu|display>\n");
        return 64;
    }
    if (strcmp(argv[1], "battery") == 0) return cmd_battery();
    if (strcmp(argv[1], "charge") == 0) return cmd_charge(argc, argv);
    if (strcmp(argv[1], "cpu") == 0) return cmd_cpu(argc, argv);
    if (strcmp(argv[1], "display") == 0) return cmd_display(argc, argv);
    if (strcmp(argv[1], "thermal") == 0) return cmd_thermal(argc, argv);
    fprintf(stderr, "unknown command\n");
    return 64;
}
