FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit for wine
RUN dpkg --add-architecture i386

# Archived sources (security is NOT on archive.debian.org)
RUN printf 'deb http://archive.debian.org/debian bullseye main contrib non-free\n\
deb http://archive.debian.org/debian bullseye-updates main contrib non-free\n' \
    > /etc/apt/sources.list

RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

RUN apt-get update && \
    apt-get install -y --no-install-recommends --allow-downgrades \
        libudev1=247.3-7+deb11u5 \
        udev=247.3-7+deb11u5 \
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
        firefox-esr \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a normal user (recommended)
RUN useradd -m -s /bin/bash user && \
    echo "user:user" | chpasswd && \
    adduser user sudo && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure XRDP to start XFCE
RUN echo "startxfce4" > /home/user/.xsession && \
    chmod +x /home/user/.xsession && \
    chown user:user /home/user/.xsession

RUN echo "#!/bin/sh\nexec startxfce4" > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# Allow anybody to start X
RUN sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || \
    echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config

# Make xrdp less strict (helps in Docker)
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini

# Add xrdp to ssl-cert group
RUN adduser xrdp ssl-cert

# Generate dbus machine-id
RUN mkdir -p /var/run/dbus && dbus-uuidgen > /var/lib/dbus/machine-id

# Simple startup script that keeps the container alive
RUN echo '#!/bin/bash\n\
rm -f /var/run/xrdp/xrdp*.pid /var/run/xrdp-sesman.pid 2>/dev/null\n\
/usr/sbin/xrdp-sesman\n\
exec /usr/sbin/xrdp -n\n' > /start.sh && chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
