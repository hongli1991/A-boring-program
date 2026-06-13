#ifndef CTCPU_h
#define CTCPU_h

#include "CTStatus.h"
#include <stdint.h>

typedef struct {
    uint64_t currentHz;
    uint64_t maxHz;
    uint64_t minHz;
    int activeCores;
    int logicalCores;
    char machine[64];
    char note[192];
} CTCPUInfo;

CTStatus CTCPURead(CTCPUInfo *info);
CTStatus CTCPUSetMaxHz(uint64_t hz);

#endif
