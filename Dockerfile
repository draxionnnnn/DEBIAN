FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386

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
        xfce4-terminal \
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
        telegram-desktop \
        papirus-icon-theme \
        arc-theme \
        python3-pil \
        fonts-dejavu-core \
        unzip \
        file-roller \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ========== NEW: Python system + pip + common modules ==========
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        build-essential \
        libssl-dev \
        libffi-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        liblzma-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Common Python modules (system-wide, python3.9)
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel && \
    pip3 install --no-cache-dir \
        requests \
        numpy \
        pandas \
        flask \
        pillow \
        beautifulsoup4 \
        lxml \
        pyyaml \
        rich \
        tqdm \
        python-dotenv

# ========== NEW: pyenv + latest Python 3.12 for user ==========
ENV PYENV_ROOT="/home/user/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

RUN curl -fsSL https://pyenv.run | bash && \
    echo 'export PYENV_ROOT="/home/user/.pyenv"' >> /home/user/.bashrc && \
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> /home/user/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> /home/user/.bashrc

# Install Python 3.12 via pyenv (for the user account)
RUN su - user -c 'pyenv install 3.12.7 && pyenv global 3.12.7' && \
    su - user -c 'pip install --no-cache-dir --upgrade pip setuptools wheel' && \
    su - user -c 'pip install --no-cache-dir numpy pandas requests flask pillow beautifulsoup4 lxml pyyaml rich tqdm python-dotenv'

# Make `python` and `pip` point to the pyenv version for the user
RUN echo 'alias python=python3' >> /home/user/.bashrc && \
    echo 'alias pip=pip3' >> /home/user/.bashrc

# ========== END NEW ==========

RUN useradd -m -s /bin/bash user && \
    echo "user:user" | chpasswd && \
    adduser user sudo && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ========== DOWNLOAD WALLPAPER ==========
RUN mkdir -p /usr/share/backgrounds /home/user/Pictures && \
    curl -k -L -o /usr/share/backgrounds/draxion-rdp.png \
    "https://i.postimg.cc/2SMMW6Hd/Chat-GPT-Image-Sep-16-2026-07-21-05-PM.png" && \
    cp /usr/share/backgrounds/draxion-rdp.png /home/user/Pictures/ && \
    chmod 644 /usr/share/backgrounds/draxion-rdp.png && \
    chown user:user /home/user/Pictures/draxion-rdp.png

# ========== XFCE CONFIG ==========
RUN mkdir -p /home/user/.config/xfce4/xfconf/xfce-perchannel-xml

RUN cat > /home/user/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Arc-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
</channel>
EOF

RUN cat > /home/user/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=8;x=0;y=0"/>
      <property name="size" type="uint" value="36"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="separator"/>
    <property name="plugin-3" type="string" value="tasklist"/>
    <property name="plugin-4" type="string" value="separator"/>
    <property name="plugin-5" type="string" value="systray"/>
    <property name="plugin-6" type="string" value="clock"/>
  </property>
</channel>
EOF

RUN cat > /home/user/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/draxion-rdp.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

RUN cat > /home/user/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
EOF

# Desktop shortcuts
RUN mkdir -p /home/user/Desktop && \
    cat > /home/user/Desktop/Telegram.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Telegram
Comment=Telegram Desktop
Exec=telegram-desktop
Icon=telegram
Terminal=false
Categories=Network;InstantMessaging;
EOF

RUN cat > /home/user/Desktop/Archive-Manager.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Archive Manager
Comment=Extract ZIP and other archives
Exec=file-roller
Icon=file-roller
Terminal=false
Categories=Utility;Archiving;
EOF

RUN chmod +x /home/user/Desktop/*.desktop

# Force wallpaper on every login
RUN mkdir -p /home/user/.config/autostart && \
    cat > /home/user/.config/autostart/force-wallpaper.sh << 'EOF'
#!/bin/bash
sleep 3
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s /usr/share/backgrounds/draxion-rdp.png
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-style -s 5
EOF

RUN chmod +x /home/user/.config/autostart/force-wallpaper.sh && \
    cat > /home/user/.config/autostart/force-wallpaper.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Force Wallpaper
Exec=/home/user/.config/autostart/force-wallpaper.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

RUN chown -R user:user /home/user

RUN echo "startxfce4" > /home/user/.xsession && chmod +x /home/user/.xsession
RUN echo "#!/bin/sh\nexec startxfce4" > /etc/xrdp/startwm.sh && chmod +x /etc/xrdp/startwm.sh
RUN sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || \
    echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini
RUN adduser xrdp ssl-cert
RUN mkdir -p /var/run/dbus && dbus-uuidgen > /var/lib/dbus/machine-id

RUN echo '#!/bin/bash\n\
rm -f /var/run/xrdp/xrdp*.pid /var/run/xrdp-sesman.pid 2>/dev/null\n\
/usr/sbin/xrdp-sesman\n\
exec /usr/sbin/xrdp -n\n' > /start.sh && chmod +x /start.sh

EXPOSE 3389
CMD ["/start.sh"]
