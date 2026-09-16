FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit for wine
RUN dpkg --add-architecture i386

# Archived sources
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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -s /bin/bash user && \
    echo "user:user" | chpasswd && \
    adduser user sudo && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ========== CREATE CUSTOM WALLPAPER "DRAXION RDP" ==========
RUN python3 - << 'EOF'
from PIL import Image, ImageDraw, ImageFont
import os

# Create dark gradient background
width, height = 1920, 1080
img = Image.new('RGB', (width, height), color=(12, 12, 18))
draw = ImageDraw.Draw(img)

# Soft purple/blue gradient effect
for y in range(height):
    r = int(12 + (y / height) * 18)
    g = int(12 + (y / height) * 8)
    b = int(28 + (y / height) * 35)
    draw.line([(0, y), (width, y)], fill=(r, g, b))

# Load font
try:
    font_big = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 92)
    font_med = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 48)
    font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 32)
except:
    font_big = ImageFont.load_default()
    font_med = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Main title
title = "DRAXION RDP"
bbox = draw.textbbox((0, 0), title, font=font_big)
tw = bbox[2] - bbox[0]
draw.text(((width - tw) // 2, height // 2 - 120), title, fill=(180, 120, 255), font=font_big)

# Telegram username
tg = "@THEDRAXION"
bbox = draw.textbbox((0, 0), tg, font=font_med)
tw = bbox[2] - bbox[0]
draw.text(((width - tw) // 2, height // 2 + 10), tg, fill=(100, 220, 255), font=font_med)

# Small tagline
tag = "OP WALLPAPER"
bbox = draw.textbbox((0, 0), tag, font=font_small)
tw = bbox[2] - bbox[0]
draw.text(((width - tw) // 2, height // 2 + 90), tag, fill=(160, 160, 180), font=font_small)

# Save wallpaper
os.makedirs("/usr/share/backgrounds", exist_ok=True)
img.save("/usr/share/backgrounds/draxion-rdp.png", "PNG")
print("Wallpaper created successfully!")
EOF

# ========== XFCE CONFIG ==========
RUN mkdir -p /home/user/.config/xfce4/xfconf/xfce-perchannel-xml

# Dark theme + icons
RUN cat > /home/user/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Arc-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
</channel>
EOF

# Clean panel
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

# Set the custom wallpaper
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

# Disable compositor for better RDP performance
RUN cat > /home/user/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
EOF

RUN chown -R user:user /home/user/.config

# XRDP settings
RUN echo "startxfce4" > /home/user/.xsession && chmod +x /home/user/.xsession
RUN echo "#!/bin/sh\nexec startxfce4" > /etc/xrdp/startwm.sh && chmod +x /etc/xrdp/startwm.sh

RUN sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || \
    echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config

RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini

RUN adduser xrdp ssl-cert
RUN mkdir -p /var/run/dbus && dbus-uuidgen > /var/lib/dbus/machine-id

# Startup
RUN echo '#!/bin/bash\n\
rm -f /var/run/xrdp/xrdp*.pid /var/run/xrdp-sesman.pid 2>/dev/null\n\
/usr/sbin/xrdp-sesman\n\
exec /usr/sbin/xrdp -n\n' > /start.sh && chmod +x /start.sh

EXPOSE 3389
CMD ["/start.sh"]
