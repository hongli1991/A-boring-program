#include "CTRoot.h"
#include <CoreFoundation/CoreFoundation.h>
#include <errno.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>

extern char **environ;
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t *attr, uid_t persona_id, uint32_t flags);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t *attr, uid_t uid);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t *attr, uid_t gid);

static bool CTRootHelperPath(char *buffer, size_t size) {
    if (!buffer || size == 0) return false;
    CFURLRef url = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("control-helper"), NULL, NULL);
    if (!url) return false;
    Boolean ok = CFURLGetFileSystemRepresentation(url, true, (UInt8 *)buffer, size);
    CFRelease(url);
    return ok;
}

CTStatus CTRootRunHelper(const char *const argv[]) {
    char helper[1024];
    if (!CTRootHelperPath(helper, sizeof(helper))) return CTStatusUnsupported;

    size_t argc = 0;
    while (argv && argv[argc]) argc++;
    char *spawnArgv[16];
    if (argc + 2 > sizeof(spawnArgv) / sizeof(spawnArgv[0])) return CTStatusInvalidArgument;
    spawnArgv[0] = helper;
    for (size_t i = 0; i < argc; i++) spawnArgv[i + 1] = (char *)argv[i];
    spawnArgv[argc + 1] = NULL;

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_set_persona_np(&attr, 99, 1);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    pid_t pid = 0;
    int err = posix_spawn(&pid, helper, NULL, &attr, spawnArgv, environ);
    posix_spawnattr_destroy(&attr);
    if (err != 0) return err == EACCES ? CTStatusPermissionDenied : CTStatusIOError;

    int status = 0;
    if (waitpid(pid, &status, 0) < 0) return CTStatusIOError;
    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) return CTStatusOK;
    return CTStatusIOError;
}
