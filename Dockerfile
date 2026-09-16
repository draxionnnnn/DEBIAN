FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386

RUN printf 'deb http://archive.debian.org/debian bullseye main contrib non-free\n\
deb http://archive.debian.org/debian bullseye-updates main contrib non-free\n' \
    > /etc/apt/sources.list

# Install xserver-xorg-core FIRST so xorgxrdp can find its ABI dependencies
RUN apt update && apt install -y \
    xserver-xorg-core \
    xserver-xorg-input-all \
    xrdp \
    xorgxrdp \
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    sudo \
    curl \
    wget \
    nano \
    net-tools \
    policykit-1 \
    pulseaudio \
    pulseaudio-utils \
    wine \
    firefox-esr && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN echo "root:root" | chpasswd

RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# CRITICAL: Replace the whole startwm.sh with a clean script
RUN printf '#!/bin/sh\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexec startxfce4\n' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

RUN mkdir -p /var/run/dbus && dbus-uuidgen > /var/lib/dbus/machine-id

RUN sed -i 's/^crypt_level=.*/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^security_layer=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini

RUN adduser xrdp ssl-cert

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
