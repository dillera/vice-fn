/*
 * Start VICE-FN: start FujiNet-PC, then VICE with FujiNet on the serial bus,
 * and stop FujiNet-PC again when VICE quits.
 *
 * The app lives in the VICE-FN_AppleSilicon folder next to VICE/ and
 * FujiNet-PC/. A FujiNet-PC that is already listening on the NetIEC port is
 * used as it is.
 */

#include <CoreFoundation/CoreFoundation.h>
#include <arpa/inet.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <netinet/in.h>
#include <signal.h>
#include <spawn.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <sysexits.h>
#include <unistd.h>

#ifndef NETIEC_PORT
#define NETIEC_PORT 1541 /* fnconfig.ini [BOIP] port */
#endif
#ifndef WEB_UI
#define WEB_UI      "http://localhost:8064"
#endif

extern char **environ;

static char base[PATH_MAX];
static char vice_dir[PATH_MAX];
static char fujinet_dir[PATH_MAX];
static volatile pid_t vice = -1;
static volatile pid_t fujinet = -1;

static void alert(const char *fmt, ...)
{
    char text[2048];
    CFStringRef msg;
    CFOptionFlags response;
    va_list ap;

    va_start(ap, fmt);
    vsnprintf(text, sizeof text, fmt, ap);
    va_end(ap);
    msg = CFStringCreateWithCString(NULL, text, kCFStringEncodingUTF8);
    CFUserNotificationDisplayAlert(0, kCFUserNotificationStopAlertLevel, NULL, NULL, NULL,
                                   CFSTR("VICE-FN"), msg, CFSTR("OK"), NULL, NULL, &response);
    if (msg)
        CFRelease(msg);
}

/* Is something accepting connections on localhost:port? */
static bool port_open(int port)
{
    struct sockaddr_in sa;
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    bool open;

    if (fd < 0)
        return false;
    memset(&sa, 0, sizeof sa);
    sa.sin_len = sizeof sa;
    sa.sin_family = AF_INET;
    sa.sin_port = htons(port);
    sa.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    open = connect(fd, (struct sockaddr *) &sa, sizeof sa) == 0;
    close(fd);
    return open;
}

/* macOS may run a downloaded app from a read-only random copy (App
 * Translocation); the folders next to it are only at the original path. */
static void untranslocate(char *path, size_t size)
{
    typedef Boolean (*is_translocated_fn)(CFURLRef, bool *, CFErrorRef *);
    typedef CFURLRef (*original_path_fn)(CFURLRef, CFErrorRef *);
    void *security = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_LAZY);
    is_translocated_fn is_translocated;
    original_path_fn original_path;
    CFURLRef url, original;
    bool translocated = false;

    if (!security)
        return;
    is_translocated = (is_translocated_fn) dlsym(security, "SecTranslocateIsTranslocatedURL");
    original_path = (original_path_fn) dlsym(security, "SecTranslocateCreateOriginalPathForURL");
    if (!is_translocated || !original_path)
        return;

    url = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *) path, strlen(path), true);
    if (!url)
        return;
    if (is_translocated(url, &translocated, NULL) && translocated) {
        original = original_path(url, NULL);
        if (original) {
            CFURLGetFileSystemRepresentation(original, true, (UInt8 *) path, size);
            CFRelease(original);
        }
    }
    CFRelease(url);
}

/* The folder that holds this app */
static bool find_base(void)
{
    char exe[PATH_MAX], path[PATH_MAX];
    uint32_t len = sizeof exe;
    char *p;

    if (_NSGetExecutablePath(exe, &len) != 0 || !realpath(exe, path))
        return false;
    p = strstr(path, ".app/Contents/MacOS/");
    if (!p)
        return false;
    p[4] = '\0';
    untranslocate(path, sizeof path);
    p = strrchr(path, '/');
    if (!p)
        return false;
    *p = '\0';
    strlcpy(base, path, sizeof base);
    return true;
}

static pid_t spawn(const char *dir, char *const argv[], char *const envp[],
                   const char *log, bool append)
{
    posix_spawn_file_actions_t actions;
    pid_t pid;
    int rc;

    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_addchdir_np(&actions, dir);
    posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0);
    posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, log,
                                     O_WRONLY | O_CREAT | (append ? O_APPEND : O_TRUNC), 0644);
    posix_spawn_file_actions_adddup2(&actions, STDOUT_FILENO, STDERR_FILENO);
    rc = posix_spawn(&pid, argv[0], &actions, NULL, argv, envp);
    posix_spawn_file_actions_destroy(&actions);
    return rc == 0 ? pid : -1;
}

static pid_t start_fujinet(bool append)
{
    char exe[PATH_MAX], log[PATH_MAX];
    char *argv[] = { exe, "-u", WEB_UI, NULL };

    snprintf(exe, sizeof exe, "%s/fujinet", fujinet_dir);
    snprintf(log, sizeof log, "%s/fujinet-pc.log", fujinet_dir);
    return spawn(fujinet_dir, argv, environ, log, append);
}

/* VICE with FujiNet as drive 8 and devices 16 (network), 29 (clock) and
 * 30 (FujiNet), reached through the NetIEC bridge libopencbm.dylib */
static pid_t start_vice(void)
{
    char exe[PATH_MAX], data[PATH_MAX], log[PATH_MAX], dyld[PATH_MAX + 32], port[32];
    char *argv[] = {
        exe, "-directory", data,
        "-drive8type", "0", "+drive8truedrive", "-devicebackend8", "2", "-trapdevice8",
        "-realdevice16", "-realdevice29", "-realdevice30",
        NULL
    };
    char **envp;
    size_t n = 0, i;
    pid_t pid;

    snprintf(exe, sizeof exe, "%s/x64sc", vice_dir);
    snprintf(data, sizeof data, "%s/data", vice_dir);
    snprintf(log, sizeof log, "%s/vice.log", vice_dir);
    snprintf(dyld, sizeof dyld, "DYLD_LIBRARY_PATH=%s", vice_dir);
    snprintf(port, sizeof port, "NETIEC_PORT=%d", NETIEC_PORT);

    while (environ[n])
        n++;
    envp = calloc(n + 3, sizeof *envp);
    if (!envp)
        return -1;
    for (i = 0, n = 0; environ[i]; i++)
        if (strncmp(environ[i], "DYLD_LIBRARY_PATH=", 18) != 0 &&
            strncmp(environ[i], "NETIEC_PORT=", 12) != 0)
            envp[n++] = environ[i];
    envp[n++] = dyld;
    envp[n] = port;

    pid = spawn(vice_dir, argv, envp, log, false);
    free(envp);
    return pid;
}

static void stop(pid_t pid)
{
    int i;

    if (pid <= 0)
        return;
    kill(pid, SIGTERM);
    for (i = 0; i < 30; i++) {
        if (waitpid(pid, NULL, WNOHANG) == pid)
            return;
        usleep(100000);
    }
    kill(pid, SIGKILL);
    waitpid(pid, NULL, 0);
}

static void on_signal(int sig)
{
    (void) sig;
    if (vice > 0)
        kill(vice, SIGTERM);
    if (fujinet > 0)
        kill(fujinet, SIGTERM);
    _exit(0);
}

int main(void)
{
    char path[PATH_MAX];
    int status, i;
    pid_t pid;

    if (!find_base()) {
        alert("Start VICE-FN can't tell which folder it is in.");
        return 1;
    }
    snprintf(vice_dir, sizeof vice_dir, "%s/VICE", base);
    snprintf(fujinet_dir, sizeof fujinet_dir, "%s/FujiNet-PC", base);

    snprintf(path, sizeof path, "%s/x64sc", vice_dir);
    if (access(path, X_OK) != 0) {
        alert("VICE wasn't found next to Start VICE-FN. "
              "Keep the app in the VICE-FN_AppleSilicon folder, with the VICE and FujiNet-PC folders.");
        return 1;
    }
    snprintf(path, sizeof path, "%s/fujinet", fujinet_dir);
    if (access(path, X_OK) != 0) {
        alert("FujiNet-PC wasn't found next to Start VICE-FN. "
              "Keep the app in the VICE-FN_AppleSilicon folder, with the VICE and FujiNet-PC folders.");
        return 1;
    }
    if (access(fujinet_dir, W_OK) != 0 || access(vice_dir, W_OK) != 0) {
        alert("FujiNet-PC needs to save its settings, but the VICE-FN_AppleSilicon folder is read only. "
              "Copy the folder somewhere you can write to, such as your Applications folder, "
              "and start it from there.");
        return 1;
    }

    signal(SIGTERM, on_signal);
    signal(SIGINT, on_signal);
    signal(SIGHUP, on_signal);

    if (!port_open(NETIEC_PORT)) {
        fujinet = start_fujinet(false);
        if (fujinet < 0) {
            alert("FujiNet-PC didn't start: %s.", strerror(errno));
            return 1;
        }
        /* Catch a FujiNet-PC that quits at once, e.g. when its ports are taken */
        for (i = 0; i < 15; i++) {
            usleep(100000);
            if (waitpid(fujinet, &status, WNOHANG) == fujinet) {
                alert("FujiNet-PC stopped as soon as it started. "
                      "Its log is %s/fujinet-pc.log.", fujinet_dir);
                return 1;
            }
        }
    }

    vice = start_vice();
    if (vice < 0) {
        alert("VICE didn't start: %s.", strerror(errno));
        stop(fujinet);
        return 1;
    }

    for (;;) {
        pid = wait(&status);
        if (pid < 0) {
            if (errno == EINTR)
                continue;
            break;
        }
        if (pid == vice)
            break;
        if (pid == fujinet) {
            /* FujiNet-PC asks for a restart with EX_TEMPFAIL, as in run-fujinet */
            if (WIFEXITED(status) && WEXITSTATUS(status) == EX_TEMPFAIL)
                fujinet = start_fujinet(true);
            else
                fujinet = -1;
        }
    }
    vice = -1;
    stop(fujinet);
    return 0;
}
