FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture (needed for wine)
RUN dpkg --add-architecture i386

# Correct archived sources (security is NOT available on archive.debian.org)
RUN printf 'deb http://archive.debian.org/debian bullseye main contrib non-free\n\
deb http://archive.debian.org/debian bullseye-updates main contrib non-free\n' \
    > /etc/apt/sources.list

# Ignore expired Release files
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
