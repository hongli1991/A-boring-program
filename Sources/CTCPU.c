#include "CTCPU.h"
#include <sys/sysctl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static uint64_t CTSysctlUInt64(const char *name) {
    uint64_t value = 0;
    size_t size = sizeof(value);
    if (sysctlbyname(name, &value, &size, NULL, 0) == 0) return value;
    uint32_t value32 = 0;
    size = sizeof(value32);
    if (sysctlbyname(name, &value32, &size, NULL, 0) == 0) return value32;
    return 0;
}

CTStatus CTCPURead(CTCPUInfo *info) {
    if (!info) return CTStatusInvalidArgument;
    memset(info, 0, sizeof(*info));
    info->currentHz = CTSysctlUInt64("hw.cpufrequency");
    info->maxHz = CTSysctlUInt64("hw.cpufrequency_max");
    info->minHz = CTSysctlUInt64("hw.cpufrequency_min");
    info->logicalCores = (int)sysconf(_SC_NPROCESSORS_CONF);
    info->activeCores = (int)sysconf(_SC_NPROCESSORS_ONLN);
    size_t machineSize = sizeof(info->machine);
    sysctlbyname("hw.machine", info->machine, &machineSize, NULL, 0);
    snprintf(info->note, sizeof(info->note), "iOS hides CPU frequency sysctls on many devices. Use thermal controls and verified PMGR backends for enforcement.");
    return CTStatusOK;
}

CTStatus CTCPUSetMaxHz(uint64_t hz) {
    if (hz == 0) return CTStatusInvalidArgument;
    uint64_t value = hz;
    int rc = sysctlbyname("hw.cpufrequency_max", NULL, NULL, &value, sizeof(value));
    if (rc == 0) return CTStatusOK;
    return CTStatusUnsupported;
}
