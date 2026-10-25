# A telnet and SSH server to try FujiNet terminal programs against.
# Log in as tester, password fujinet.
FROM ubuntu:24.04
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openssh-server inetutils-inetd inetutils-telnetd procps less \
 && rm -rf /var/lib/apt/lists/*
# A container has no login UID to set: don't refuse logins over it
RUN sed -i 's/^session\s\+required\s\+pam_loginuid.so/session optional pam_loginuid.so/' \
        /etc/pam.d/login /etc/pam.d/sshd \
 && useradd -m -s /bin/bash tester && echo tester:fujinet | chpasswd \
 && mkdir -p /run/sshd \
 && (grep -q '^telnet' /etc/inetd.conf || \
     echo 'telnet stream tcp nowait root /usr/sbin/telnetd telnetd' >> /etc/inetd.conf)
EXPOSE 22 23
CMD /usr/sbin/sshd && exec /usr/sbin/inetutils-inetd -d
