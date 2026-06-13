#ifndef CTStatus_h
#define CTStatus_h

#include <stdbool.h>

typedef enum {
    CTStatusOK = 0,
    CTStatusUnsupported = 1,
    CTStatusPermissionDenied = 2,
    CTStatusInvalidArgument = 3,
    CTStatusIOError = 4
} CTStatus;

static inline const char *CTStatusDescription(CTStatus status) {
    switch (status) {
        case CTStatusOK: return "OK";
        case CTStatusUnsupported: return "Unsupported on this device/build";
        case CTStatusPermissionDenied: return "Permission denied";
        case CTStatusInvalidArgument: return "Invalid argument";
        case CTStatusIOError: return "I/O error";
    }
    return "Unknown";
}

#endif
