FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386

# Pin apt to a Debian bullseye snapshot (before EOL) so all packages resolve
RUN printf 'deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20250801T000000Z bullseye main contrib non-free\n\
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20250801T000000Z bullseye-updates main contrib non-free\n\
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/20250801T000000Z bullseye-security main contrib non-free\n' \
    > /etc/apt/sources.list

# Install everything (wine32:i386 removed to avoid libc6:i386 mismatch)
RUN apt update && apt install -y \
    xrdp \
    xfce4 \
    xfce4-goodies \
    xorg \
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

# Set root password
RUN echo "root:root" | chpasswd

# Ensure Xwrapper allows any user
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Root session
RUN echo "startxfce4" > /root/.xsession && chmod 700 /root/.xsession

# Generate machine-id for dbus
RUN mkdir -p /var/run/dbus && dbus-uuidgen > /var/lib/dbus/machine-id

# xrdp config: lower crypto + plain RDP layer
RUN sed -i 's/^crypt_level=.*/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^security_layer=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini

# Make startwm.sh launch XFCE (append, don't overwrite the whole file)
RUN printf '\nif [ -r /etc/profile ]; then . /etc/profile; fi\nexec startxfce4\n' >> /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

RUN adduser xrdp ssl-cert

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
