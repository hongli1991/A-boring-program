#ifndef CTCPU_h
#define CTCPU_h

#include "CTStatus.h"
#include <stdint.h>

typedef struct {
    uint64_t currentHz;
    uint64_t maxHz;
    uint64_t minHz;
    char note[192];
} CTCPUInfo;

CTStatus CTCPURead(CTCPUInfo *info);
CTStatus CTCPUSetMaxHz(uint64_t hz);

#endif
