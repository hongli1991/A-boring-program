#ifndef CTChargePolicy_h
#define CTChargePolicy_h

#include "CTStatus.h"

typedef struct {
    bool enabled;
    float maxPercent;
    bool stopWhenPluggedIn;
} CTChargePolicy;

CTStatus CTChargePolicyRead(CTChargePolicy *policy);
CTStatus CTChargePolicyWrite(const CTChargePolicy *policy);

#endif
