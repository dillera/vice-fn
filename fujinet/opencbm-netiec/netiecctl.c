/*
 * netiecctl.c - drive FujiNet-PC over NetIEC through the same OpenCBM ABI that
 * VICE uses, without an emulator.
 *
 *   netiecctl status <dev>                     read the command channel
 *   netiecctl command <dev> <text>             send a command on channel 15
 *   netiecctl dir <dev>                        print the directory ("$")
 *   netiecctl load <dev> <name> <outfile>      save a file from the device
 *   netiecctl fuji <cmd> [payload] [replylen]  FujiNet command on device 30,
 *                                              cmd/payload in hex, as fujinet-lib sends it
 */

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef void *CBM_FILE;

int cbm_driver_open(CBM_FILE *f, int port);
void cbm_driver_close(CBM_FILE f);
const char *cbm_get_driver_name(int port);
int cbm_listen(CBM_FILE f, unsigned char dev, unsigned char secadr);
int cbm_talk(CBM_FILE f, unsigned char dev, unsigned char secadr);
int cbm_open(CBM_FILE f, unsigned char dev, unsigned char secadr, const void *fname, size_t len);
int cbm_close(CBM_FILE f, unsigned char dev, unsigned char secadr);
int cbm_raw_read(CBM_FILE f, void *buf, size_t size);
int cbm_raw_write(CBM_FILE f, const void *buf, size_t size);
int cbm_unlisten(CBM_FILE f);
int cbm_untalk(CBM_FILE f);
int cbm_get_eoi(CBM_FILE f);

#define FUJI_DEVICE   30
#define FUJI_CHANNEL  15
#define MAX_TRANSFER  65536

/* read from the current talker until EOI, one byte at a time like VICE does */
static int read_until_eoi(CBM_FILE f, uint8_t *buf, int size)
{
    int total = 0;

    while (total < size) {
        int n = cbm_raw_read(f, buf + total, 1);
        if (n < 0) {
            return -1;
        }
        total += n;
        if (n == 0 || cbm_get_eoi(f)) {
            break;
        }
    }
    return total;
}

static void hexdump(const uint8_t *buf, int len)
{
    for (int i = 0; i < len; i += 16) {
        printf("%04x  ", i);
        for (int j = 0; j < 16; j++) {
            if (i + j < len) {
                printf("%02x ", buf[i + j]);
            } else {
                printf("   ");
            }
        }
        printf(" ");
        for (int j = 0; j < 16 && i + j < len; j++) {
            putchar(isprint(buf[i + j]) ? buf[i + j] : '.');
        }
        putchar('\n');
    }
}

static int parse_hex(const char *text, uint8_t *out, int size)
{
    int len = 0;

    while (*text != '\0' && len < size) {
        unsigned value;
        if (*text == ' ' || *text == ':') {
            text++;
            continue;
        }
        if (sscanf(text, "%2x", &value) != 1) {
            return -1;
        }
        out[len++] = (uint8_t)value;
        text += (text[1] != '\0') ? 2 : 1;
    }
    return len;
}

static int cmd_status(CBM_FILE f, int dev)
{
    uint8_t buf[256];
    int len;

    if (cbm_talk(f, dev, 15) != 0) {
        fprintf(stderr, "device %d not present\n", dev);
        return 1;
    }
    len = read_until_eoi(f, buf, sizeof buf - 1);
    cbm_untalk(f);
    if (len < 0) {
        return 1;
    }
    buf[len] = '\0';
    printf("%s\n", (char *)buf);
    return 0;
}

static int cmd_command(CBM_FILE f, int dev, const char *text)
{
    int len = (int)strlen(text);

    if (cbm_listen(f, dev, 15) != 0) {
        fprintf(stderr, "device %d not present\n", dev);
        return 1;
    }
    if (cbm_raw_write(f, text, len) != len) {
        fprintf(stderr, "device %d did not take the whole command\n", dev);
    }
    cbm_unlisten(f);
    return cmd_status(f, dev);
}

static int read_file(CBM_FILE f, int dev, const char *name, uint8_t *buf, int size)
{
    int len;

    if (cbm_open(f, dev, 0, name, strlen(name)) != 0) {
        fprintf(stderr, "device %d not present\n", dev);
        return -1;
    }
    cbm_talk(f, dev, 0);
    len = read_until_eoi(f, buf, size);
    cbm_untalk(f);
    cbm_close(f, dev, 0);
    return len;
}

/* the directory comes back as a BASIC program: link, line number, text */
static int cmd_dir(CBM_FILE f, int dev)
{
    static uint8_t buf[MAX_TRANSFER];
    int len = read_file(f, dev, "$", buf, sizeof buf);
    int pos = 2;

    if (len <= 2) {
        fprintf(stderr, "no directory\n");
        return 1;
    }
    while (pos + 4 <= len && (buf[pos] | buf[pos + 1]) != 0) {
        printf("%u ", buf[pos + 2] | (buf[pos + 3] << 8));
        pos += 4;
        while (pos < len && buf[pos] != 0) {
            putchar(isprint(buf[pos]) ? buf[pos] : '.');
            pos++;
        }
        putchar('\n');
        pos++;
    }
    return 0;
}

static int cmd_load(CBM_FILE f, int dev, const char *name, const char *outfile)
{
    static uint8_t buf[MAX_TRANSFER];
    int len = read_file(f, dev, name, buf, sizeof buf);
    FILE *out;

    if (len <= 0) {
        fprintf(stderr, "file not found\n");
        return 1;
    }
    out = fopen(outfile, "wb");
    if (out == NULL || fwrite(buf, 1, len, out) != (size_t)len) {
        perror(outfile);
        return 1;
    }
    fclose(out);
    printf("%d bytes, load address $%04x\n", len, len >= 2 ? buf[0] | (buf[1] << 8) : 0);
    return 0;
}

/* the same sequence as fuji_bus_call() in fujinet-lib's bus/c64/fujinet-bus-c64.c */
static int cmd_fuji(CBM_FILE f, const char *command, const char *payload_hex, int reply_len)
{
    uint8_t name[2], payload[512], reply[MAX_TRANSFER];
    int payload_len = 0, len;

    if (parse_hex(command, name + 1, 1) != 1) {
        fprintf(stderr, "bad command byte\n");
        return 1;
    }
    if (payload_hex != NULL) {
        payload_len = parse_hex(payload_hex, payload, sizeof payload);
        if (payload_len < 0) {
            fprintf(stderr, "bad payload\n");
            return 1;
        }
    }
    name[0] = payload_len > 0 ? 0x02 : 0x01;

    if (cbm_open(f, FUJI_DEVICE, FUJI_CHANNEL, name, sizeof name) != 0) {
        fprintf(stderr, "FujiNet device %d not present\n", FUJI_DEVICE);
        return 1;
    }
    if (payload_len > 0) {
        cbm_listen(f, FUJI_DEVICE, FUJI_CHANNEL);
        if (cbm_raw_write(f, payload, payload_len) != payload_len) {
            fprintf(stderr, "payload not accepted\n");
        }
        cbm_unlisten(f);
    }
    len = 0;
    if (reply_len != 0) {
        cbm_talk(f, FUJI_DEVICE, FUJI_CHANNEL);
        len = read_until_eoi(f, reply, reply_len > 0 ? reply_len : (int)sizeof reply);
        cbm_untalk(f);
    }
    cbm_close(f, FUJI_DEVICE, FUJI_CHANNEL);
    if (len < 0) {
        return 1;
    }
    printf("%d byte reply\n", len);
    hexdump(reply, len);
    return 0;
}

static void usage(void)
{
    fprintf(stderr,
            "usage: netiecctl status <dev>\n"
            "       netiecctl command <dev> <text>\n"
            "       netiecctl dir <dev>\n"
            "       netiecctl load <dev> <name> <outfile>\n"
            "       netiecctl fuji <cmd hex> [payload hex] [reply length, -1 = until EOI]\n"
            "FujiNet-PC address comes from NETIEC_HOST/NETIEC_PORT; NETIEC_TRACE=1 logs traffic.\n");
}

int main(int argc, char **argv)
{
    CBM_FILE f;
    int rc = 1;

    if (argc < 2) {
        usage();
        return 1;
    }
    if (cbm_driver_open(&f, 0) != 0) {
        fprintf(stderr, "cannot open %s\n", cbm_get_driver_name(0));
        return 1;
    }

    if (strcmp(argv[1], "status") == 0 && argc == 3) {
        rc = cmd_status(f, atoi(argv[2]));
    } else if (strcmp(argv[1], "command") == 0 && argc == 4) {
        rc = cmd_command(f, atoi(argv[2]), argv[3]);
    } else if (strcmp(argv[1], "dir") == 0 && argc == 3) {
        rc = cmd_dir(f, atoi(argv[2]));
    } else if (strcmp(argv[1], "load") == 0 && argc == 5) {
        rc = cmd_load(f, atoi(argv[2]), argv[3], argv[4]);
    } else if (strcmp(argv[1], "fuji") == 0 && argc >= 3 && argc <= 5) {
        rc = cmd_fuji(f, argv[2], argc >= 4 && argv[3][0] != '\0' ? argv[3] : NULL,
                      argc == 5 ? atoi(argv[4]) : -1);
    } else {
        usage();
    }

    cbm_driver_close(f);
    return rc;
}
