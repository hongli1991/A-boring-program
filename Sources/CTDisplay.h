#ifndef CTDisplay_h
#define CTDisplay_h

#include "CTStatus.h"

typedef struct {
    int preferredMaxFps;
    int currentMaxFps;
    char panelId[256];
} CTDisplayInfo;

CTStatus CTDisplayRead(CTDisplayInfo *info);
CTStatus CTDisplaySetPreferredMaxFPS(int fps);

#endif
