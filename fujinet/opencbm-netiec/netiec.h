/*
 * netiec.h - NetIEC wire protocol, as served by FujiNet-PC's IEC bus
 * (fujinet-firmware lib/bus/iec/NetIEC.h is the authoritative definition).
 *
 * Every frame is [command u8][payload length u16le][payload]. The client sends
 * one request and waits for exactly one reply whose command is request|0x80.
 */

#ifndef NETIEC_H
#define NETIEC_H

#define NETIEC_VERSION          1

#define NETIEC_CMD_HELLO        0x01  /* [version][name]      -> [version][u32le device mask][name] */
#define NETIEC_CMD_ATN          0x02  /* [primary][secondary] -> [status: 0 ack, 1 not present] */
#define NETIEC_CMD_WRITE        0x03  /* [flags][data...]     -> [u16le bytes accepted] */
#define NETIEC_CMD_READ         0x04  /* [u16le max bytes]    -> [flags][data...] */
#define NETIEC_CMD_RESET        0x05  /* []                   -> [] */

#define NETIEC_REPLY            0x80
#define NETIEC_UNSUPPORTED      0xFF  /* reply to an unknown request: [request command] */

#define NETIEC_FLAG_EOI         0x01  /* WRITE: last byte carries EOI; READ: the talker is done */

#define NETIEC_ATN_ACKNOWLEDGED 0x00
#define NETIEC_ATN_NOT_PRESENT  0x01

#define NETIEC_HEADER_SIZE      3
#define NETIEC_MAX_PAYLOAD      0xFFFF

/* IEC bus commands sent under ATN */
#define IEC_LISTEN              0x20
#define IEC_TALK                0x40
#define IEC_SECOND              0x60
#define IEC_CLOSE               0xE0
#define IEC_OPEN                0xF0
#define IEC_UNLISTEN            0x3F
#define IEC_UNTALK              0x5F

#define NETIEC_DEFAULT_HOST     "127.0.0.1"
#define NETIEC_DEFAULT_PORT     "1541"

#endif
