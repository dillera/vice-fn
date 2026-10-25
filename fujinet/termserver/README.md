# termserver

A telnet and SSH server in Docker (Ubuntu 24.04), to try FujiNet terminal
programs such as CaTer against.

    docker build -t cater-termserver fujinet/termserver
    docker run -d --name cater-termserver -p 127.0.0.1:2323:23 -p 127.0.0.1:2222:22 cater-termserver

Log in as `tester`, password `fujinet`. The ports are only on 127.0.0.1. In
CaTer on the C64:
- `telnet://localhost:2323?term=vt100&cols=40&rows=25`
- `ssh://tester:fujinet@127.0.0.1:2222?term=vt100&cols=40&rows=25`

Without the `?term=...` part the shell gets FujiNet's defaults: `dumb` and no
size for telnet, `vanilla` and 80x24 for SSH.

SSH needs `127.0.0.1`, not `localhost`: FujiNet-PC's libssh connects only to
the first address of `localhost`, which on macOS is `::1`, where Docker's
forwarded port isn't listening.

`docker rm -f cater-termserver` stops and removes it.
