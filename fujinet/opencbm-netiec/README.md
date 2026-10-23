# opencbm-netiec

A shared library with the OpenCBM ABI that VICE's real-device support loads
(`libopencbm.dylib` on macOS, `libopencbm.so` on Linux). Instead of driving an
IEC cable it sends each bus transaction over TCP, using the NetIEC protocol, to
FujiNet-PC built with `FUJINET_TARGET=IEC`.

## Build

    make            # libopencbm.dylib/.so and netiecctl

## Settings

| Variable | Default | |
|---|---|---|
| `NETIEC_HOST` | `127.0.0.1` | FujiNet-PC host |
| `NETIEC_PORT` | `1541` | FujiNet-PC `[BOIP] port` |
| `NETIEC_TIMEOUT` | `30` | seconds to wait for a reply |
| `NETIEC_TRACE` | `0` | `1` logs every transaction to stderr |

The library connects on demand and retries once a second, so VICE and
FujiNet-PC can start in either order.

## netiecctl

`netiecctl` talks to FujiNet-PC through the same ABI, without an emulator:

    ./netiecctl status 8                 # read a drive's command channel
    ./netiecctl dir 8                    # directory of "$"
    ./netiecctl load 8 config.prg out.prg
    ./netiecctl fuji e8                  # GET_ADAPTERCONFIG on device 30, as fujinet-lib sends it

## NetIEC protocol (v1)

Every frame is `[command u8][payload length u16le][payload]`. The client sends
one request and reads exactly one reply whose command is the request's with bit
7 set; an unknown request gets `0xFF` with the request command as payload.
FujiNet-PC defines the protocol in `lib/bus/iec/NetIEC.h`.

| Request | Payload | Reply payload |
|---|---|---|
| `0x01` HELLO | version, client name | version, `u32le` mask of device numbers present, server name |
| `0x02` ATN | primary [, secondary], the bytes sent under ATN | `0` acknowledged, `1` device not present |
| `0x03` WRITE | flags (bit 0: EOI on the last byte), data | `u16le` bytes the listener took |
| `0x04` READ | `u16le` most bytes wanted | flags (bit 0: EOI, the talker is done), data |
| `0x05` RESET | none | none |

The server holds a WRITE or READ reply while the device asks for more time,
just as an IEC device holds the bus. Bytes returned by READ are consumed even if
the client stops before using them.

VICE hands the library one byte per write and drops the KERNAL's EOI, so writes
carry no EOI; FujiNet ends a command or file name at UNLISTEN.
