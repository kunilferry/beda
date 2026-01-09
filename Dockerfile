FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# =============================
# System & Desktop Environment
# =============================
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server \
    novnc websockify \
    sudo xterm \
    systemd snapd \
    vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    software-properties-common \
    openssl \
    ca-certificates \
    xubuntu-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# =============================
# Firefox (NON-SNAP, OFFICIAL PPA)
# =============================
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox && \
    rm -rf /var/lib/apt/lists/*

# =============================
# VNC Startup Script (KIOSK)
# =============================
RUN mkdir -p /root/.vnc && \
    printf '#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
exec startxfce4 &\n\
sleep 3\n\
firefox --kiosk --no-remote --private-window https://tes-one-bay.vercel.app/\n' \
    > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Xauthority
RUN touch /root/.Xauthority

# =============================
# Expose (Railway uses $PORT)
# =============================
EXPOSE 6080

# =============================
# Run VNC + noVNC (Railway compatible)
# =============================
CMD bash -c "\
vncserver :1 -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && \
openssl req -new -subj '/C=JP' -x509 -days 365 -nodes -out self.pem -keyout self.pem && \
websockify --web=/usr/share/novnc/ --cert=self.pem $PORT localhost:5901 && \
tail -f /dev/null"
