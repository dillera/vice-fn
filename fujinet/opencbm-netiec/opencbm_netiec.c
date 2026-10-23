/*
 * opencbm_netiec.c - the OpenCBM ABI, carried over NetIEC instead of an IEC cable.
 *
 * VICE's real-device support (src/serial/realdevice.c) dlopen()s libopencbm and
 * calls these functions for every IEC transaction aimed at a "real device" unit.
 * This library answers them by talking NetIEC to FujiNet-PC, so the emulated
 * computer reaches FujiNet-PC's devices as if they were on its serial bus.
 *
 * Environment:
 *   NETIEC_HOST     FujiNet-PC host (default 127.0.0.1)
 *   NETIEC_PORT     FujiNet-PC NetIEC port (default 1541)
 *   NETIEC_TIMEOUT  seconds to wait for a reply (default 30)
 *   NETIEC_TRACE    set to 1 to log every transaction to stderr
 */

#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <poll.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include "netiec.h"

#define CBMAPI __attribute__((visibility("default")))

/* matches lib/opencbm.h on Linux and macOS */
typedef void *CBM_FILE;

#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif

#define CONNECT_TIMEOUT_MS  1000
#define RECONNECT_DELAY_MS  1000

typedef struct netiec_s {
    int fd;
    char host[256];
    char port[16];
    int timeout_ms;
    int trace;
    int eoi;
    int64_t next_connect_ms;
    uint32_t device_mask;
    char server[64];
} netiec_t;

static char driver_name[320];

static int64_t now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static void trace(const netiec_t *c, const char *fmt, ...)
{
    va_list ap;

    if (!c->trace) {
        return;
    }
    va_start(ap, fmt);
    fputs("netiec: ", stderr);
    vfprintf(stderr, fmt, ap);
    fputc('\n', stderr);
    va_end(ap);
}

static const char *env_or(const char *name, const char *fallback)
{
    const char *value = getenv(name);
    return (value != NULL && *value != '\0') ? value : fallback;
}

static void disconnect(netiec_t *c)
{
    if (c->fd >= 0) {
        close(c->fd);
        c->fd = -1;
        trace(c, "disconnected from %s:%s", c->host, c->port);
    }
}

/* wait until the socket is readable (events=POLLIN) or writable (POLLOUT) */
static int wait_socket(int fd, short events, int timeout_ms)
{
    struct pollfd pfd;
    int rc;

    pfd.fd = fd;
    pfd.events = events;
    pfd.revents = 0;
    do {
        rc = poll(&pfd, 1, timeout_ms);
    } while (rc < 0 && errno == EINTR);
    return rc > 0 ? 0 : -1;
}

static int send_all(netiec_t *c, const uint8_t *buf, size_t len)
{
    while (len > 0) {
        ssize_t n = send(c->fd, buf, len, MSG_NOSIGNAL);
        if (n < 0 && errno == EINTR) {
            continue;
        }
        if (n <= 0) {
            return -1;
        }
        buf += n;
        len -= (size_t)n;
    }
    return 0;
}

static int recv_all(netiec_t *c, uint8_t *buf, size_t len, int64_t deadline_ms)
{
    while (len > 0) {
        int64_t left = deadline_ms - now_ms();
        ssize_t n;

        if (left <= 0 || wait_socket(c->fd, POLLIN, (int)left) < 0) {
            trace(c, "timed out waiting for FujiNet-PC");
            return -1;
        }
        n = recv(c->fd, buf, len, 0);
        if (n < 0 && errno == EINTR) {
            continue;
        }
        if (n <= 0) {
            return -1;
        }
        buf += n;
        len -= (size_t)n;
    }
    return 0;
}

static int send_frame(netiec_t *c, uint8_t command, const uint8_t *payload, size_t len)
{
    uint8_t header[NETIEC_HEADER_SIZE];

    header[0] = command;
    header[1] = (uint8_t)(len & 0xff);
    header[2] = (uint8_t)(len >> 8);
    if (send_all(c, header, sizeof header) < 0) {
        return -1;
    }
    return len > 0 ? send_all(c, payload, len) : 0;
}

/* receive one frame; payload beyond reply_size is read and dropped */
static int recv_frame(netiec_t *c, uint8_t *command, uint8_t *reply, size_t reply_size,
                      size_t *reply_len, int64_t deadline_ms)
{
    uint8_t header[NETIEC_HEADER_SIZE];
    size_t len, keep;

    if (recv_all(c, header, sizeof header, deadline_ms) < 0) {
        return -1;
    }
    *command = header[0];
    len = (size_t)header[1] | ((size_t)header[2] << 8);
    keep = len < reply_size ? len : reply_size;
    if (keep > 0 && recv_all(c, reply, keep, deadline_ms) < 0) {
        return -1;
    }
    for (; len > keep; len--) {
        uint8_t dropped;
        if (recv_all(c, &dropped, 1, deadline_ms) < 0) {
            return -1;
        }
    }
    *reply_len = keep;
    return 0;
}

static int open_socket(netiec_t *c)
{
    struct addrinfo hints, *res, *ai;
    int fd = -1;

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    if (getaddrinfo(c->host, c->port, &hints, &res) != 0) {
        trace(c, "cannot resolve %s", c->host);
        return -1;
    }

    for (ai = res; ai != NULL; ai = ai->ai_next) {
        int flags, one = 1, rc;

        fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
        if (fd < 0) {
            continue;
        }
        flags = fcntl(fd, F_GETFL, 0);
        fcntl(fd, F_SETFL, flags | O_NONBLOCK);
        rc = connect(fd, ai->ai_addr, ai->ai_addrlen);
        if (rc < 0 && errno == EINPROGRESS && wait_socket(fd, POLLOUT, CONNECT_TIMEOUT_MS) == 0) {
            int err = 0;
            socklen_t errlen = sizeof err;
            getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &errlen);
            rc = err == 0 ? 0 : -1;
        }
        if (rc == 0) {
            fcntl(fd, F_SETFL, flags);
            setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
#ifdef SO_NOSIGPIPE
            setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof one);
#endif
            break;
        }
        close(fd);
        fd = -1;
    }
    freeaddrinfo(res);
    return fd;
}

/* HELLO also resynchronizes: a reply left over from a previous connection is skipped */
static int hello(netiec_t *c)
{
    static const char client[] = "VICE opencbm-netiec";
    uint8_t request[1 + sizeof client - 1];
    uint8_t reply[128];
    uint8_t command;
    size_t len;
    int64_t deadline = now_ms() + c->timeout_ms;

    request[0] = NETIEC_VERSION;
    memcpy(request + 1, client, sizeof client - 1);
    if (send_frame(c, NETIEC_CMD_HELLO, request, sizeof request) < 0) {
        return -1;
    }
    do {
        if (recv_frame(c, &command, reply, sizeof reply, &len, deadline) < 0) {
            return -1;
        }
    } while (command != (NETIEC_CMD_HELLO | NETIEC_REPLY));

    if (len < 5) {
        return -1;
    }
    c->device_mask = (uint32_t)reply[1] | ((uint32_t)reply[2] << 8) |
                     ((uint32_t)reply[3] << 16) | ((uint32_t)reply[4] << 24);
    len -= 5;
    if (len >= sizeof c->server) {
        len = sizeof c->server - 1;
    }
    memcpy(c->server, reply + 5, len);
    c->server[len] = '\0';
    trace(c, "connected to %s (NetIEC v%u) at %s:%s, devices 0x%08x",
          c->server, reply[0], c->host, c->port, (unsigned)c->device_mask);
    return 0;
}

static int ensure_connected(netiec_t *c)
{
    if (c->fd >= 0) {
        return 0;
    }
    if (now_ms() < c->next_connect_ms) {
        return -1;
    }
    c->fd = open_socket(c);
    if (c->fd < 0 || hello(c) < 0) {
        disconnect(c);
        c->next_connect_ms = now_ms() + RECONNECT_DELAY_MS;
        trace(c, "FujiNet-PC not reachable at %s:%s", c->host, c->port);
        return -1;
    }
    return 0;
}

static int transact(netiec_t *c, uint8_t command, const uint8_t *payload, size_t len,
                    uint8_t *reply, size_t reply_size, size_t *reply_len)
{
    uint8_t reply_command;

    if (ensure_connected(c) < 0) {
        return -1;
    }
    if (send_frame(c, command, payload, len) < 0 ||
        recv_frame(c, &reply_command, reply, reply_size, reply_len,
                   now_ms() + c->timeout_ms) < 0) {
        disconnect(c);
        return -1;
    }
    if (reply_command != (command | NETIEC_REPLY)) {
        trace(c, "unexpected reply 0x%02x to request 0x%02x", reply_command, command);
        disconnect(c);
        return -1;
    }
    return 0;
}

static int atn(netiec_t *c, uint8_t primary, int has_secondary, uint8_t secondary)
{
    uint8_t request[2];
    uint8_t status;
    size_t len;

    request[0] = primary;
    request[1] = secondary;
    if (transact(c, NETIEC_CMD_ATN, request, has_secondary ? 2 : 1, &status, 1, &len) < 0) {
        return -1;
    }
    if (has_secondary) {
        trace(c, "ATN %02x %02x -> %s", primary, secondary,
              status == NETIEC_ATN_ACKNOWLEDGED ? "ack" : "not present");
    } else {
        trace(c, "ATN %02x -> %s", primary, status == NETIEC_ATN_ACKNOWLEDGED ? "ack" : "not present");
    }
    return (len == 1 && status == NETIEC_ATN_ACKNOWLEDGED) ? 0 : -1;
}

static int write_bytes(netiec_t *c, const uint8_t *data, size_t size)
{
    uint8_t request[1 + 1024];
    size_t total = 0;

    while (total < size) {
        size_t chunk = size - total;
        uint8_t reply[2];
        size_t len, accepted;

        if (chunk > sizeof request - 1) {
            chunk = sizeof request - 1;
        }
        request[0] = 0;
        memcpy(request + 1, data + total, chunk);
        if (transact(c, NETIEC_CMD_WRITE, request, chunk + 1, reply, sizeof reply, &len) < 0 ||
            len != 2) {
            return total > 0 ? (int)total : -1;
        }
        accepted = (size_t)reply[0] | ((size_t)reply[1] << 8);
        trace(c, "WRITE %u -> %u accepted", (unsigned)chunk, (unsigned)accepted);
        total += accepted;
        if (accepted < chunk) {
            break;
        }
    }
    return (int)total;
}

static int read_bytes(netiec_t *c, uint8_t *data, size_t size)
{
    uint8_t request[2];
    uint8_t reply[1 + 1024];
    size_t total = 0;

    c->eoi = 0;
    while (total < size && !c->eoi) {
        size_t chunk = size - total;
        size_t len;

        if (chunk > sizeof reply - 1) {
            chunk = sizeof reply - 1;
        }
        request[0] = (uint8_t)(chunk & 0xff);
        request[1] = (uint8_t)(chunk >> 8);
        if (transact(c, NETIEC_CMD_READ, request, sizeof request, reply, sizeof reply, &len) < 0 ||
            len < 1) {
            return total > 0 ? (int)total : -1;
        }
        c->eoi = (reply[0] & NETIEC_FLAG_EOI) != 0;
        memcpy(data + total, reply + 1, len - 1);
        total += len - 1;
        trace(c, "READ %u -> %u%s", (unsigned)chunk, (unsigned)(len - 1), c->eoi ? " EOI" : "");
        if (len - 1 < chunk) {
            break;
        }
    }
    return (int)total;
}

/* ------------------------------------------------------------------------ */
/* The OpenCBM ABI resolved by VICE's opencbmlib.c                           */

CBMAPI int cbm_driver_open(CBM_FILE *f, int port)
{
    netiec_t *c = calloc(1, sizeof *c);
    const char *timeout;

    (void)port;
    if (c == NULL) {
        return -1;
    }
    c->fd = -1;
    snprintf(c->host, sizeof c->host, "%s", env_or("NETIEC_HOST", NETIEC_DEFAULT_HOST));
    snprintf(c->port, sizeof c->port, "%s", env_or("NETIEC_PORT", NETIEC_DEFAULT_PORT));
    timeout = env_or("NETIEC_TIMEOUT", "30");
    c->timeout_ms = atoi(timeout) > 0 ? atoi(timeout) * 1000 : 30000;
    c->trace = atoi(env_or("NETIEC_TRACE", "0")) != 0;

    /* FujiNet-PC may start after the emulator: connecting is retried on demand */
    ensure_connected(c);
    *f = c;
    return 0;
}

CBMAPI void cbm_driver_close(CBM_FILE f)
{
    netiec_t *c = f;

    if (c != NULL) {
        disconnect(c);
        free(c);
    }
}

CBMAPI const char *cbm_get_driver_name(int port)
{
    (void)port;
    snprintf(driver_name, sizeof driver_name, "NetIEC (FujiNet-PC at %s:%s)",
             env_or("NETIEC_HOST", NETIEC_DEFAULT_HOST), env_or("NETIEC_PORT", NETIEC_DEFAULT_PORT));
    return driver_name;
}

CBMAPI int cbm_listen(CBM_FILE f, unsigned char dev, unsigned char secadr)
{
    return atn(f, IEC_LISTEN | (dev & 0x1f), 1, IEC_SECOND | (secadr & 0x0f));
}

CBMAPI int cbm_talk(CBM_FILE f, unsigned char dev, unsigned char secadr)
{
    return atn(f, IEC_TALK | (dev & 0x1f), 1, IEC_SECOND | (secadr & 0x0f));
}

CBMAPI int cbm_unlisten(CBM_FILE f)
{
    return atn(f, IEC_UNLISTEN, 0, 0);
}

CBMAPI int cbm_untalk(CBM_FILE f)
{
    return atn(f, IEC_UNTALK, 0, 0);
}

CBMAPI int cbm_open(CBM_FILE f, unsigned char dev, unsigned char secadr,
                    const void *fname, size_t len)
{
    int rc = atn(f, IEC_LISTEN | (dev & 0x1f), 1, IEC_OPEN | (secadr & 0x0f));

    /* without a name the device stays listening for one sent by cbm_raw_write() */
    if (rc == 0 && fname != NULL) {
        if (len == 0) {
            len = strlen(fname);
        }
        if (write_bytes(f, fname, len) != (int)len) {
            rc = -1;
        }
        cbm_unlisten(f);
    }
    return rc;
}

CBMAPI int cbm_close(CBM_FILE f, unsigned char dev, unsigned char secadr)
{
    int rc = atn(f, IEC_LISTEN | (dev & 0x1f), 1, IEC_CLOSE | (secadr & 0x0f));

    cbm_unlisten(f);
    return rc;
}

/* VICE writes one byte per call and the KERNAL's EOI does not reach it, so
   writes carry no EOI; FujiNet ends commands and file names at UNLISTEN. */
CBMAPI int cbm_raw_write(CBM_FILE f, const void *buf, size_t size)
{
    return write_bytes(f, buf, size);
}

CBMAPI int cbm_raw_read(CBM_FILE f, void *buf, size_t size)
{
    return read_bytes(f, buf, size);
}

CBMAPI int cbm_get_eoi(CBM_FILE f)
{
    netiec_t *c = f;
    return c->eoi;
}

CBMAPI int cbm_reset(CBM_FILE f)
{
    uint8_t reply[1];
    size_t len;
    int rc = transact(f, NETIEC_CMD_RESET, NULL, 0, reply, sizeof reply, &len);

    trace(f, "RESET -> %s", rc == 0 ? "ok" : "failed");
    return rc;
}
