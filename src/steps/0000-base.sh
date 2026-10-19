#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Debian's own repositories, with all four components that their Release
# files list, so apt also finds packages in contrib and non-free. The write
# comes before the first apt_install, because that call runs apt-get update.
sudo tee /etc/apt/sources.list >/dev/null <<EOF
deb http://deb.debian.org/debian/ $CODENAME main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $CODENAME main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ $CODENAME-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $CODENAME-updates main contrib non-free non-free-firmware
EOF

# fonts
apt_install \
  fonts-jetbrains-mono fonts-inter

# terminal cli tools
apt_install \
  ssh git blueprint-compiler rsync jq tree htop wget ripgrep curl ffmpeg net-tools ninja-build build-essential mesa-utils \
  libtool autoconf automake cmake gcc make unzip p7zip-full patch gettext \
  bison re2c byacc pkg-config libgraph-easy-perl tree-sitter-cli \
  xsel xclip wl-clipboard linux-perf valgrind gnupg2 g++ ca-certificates

# gui tools
apt_install \
  gimp qbittorrent vlc calibre simple-scan

# libraries
apt_install \
  libfuse2 libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libxcb-xtest0 libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxml2-utils libxcb-cursor0 libxmlsec1-dev libffi-dev liblzma-dev \
  ncurses-dev libgdal-dev libpq-dev libldap2-dev libsasl2-dev \
  libasound2-dev libfontconfig-dev libwayland-dev libxkbcommon-x11-dev \
  libzstd-dev libvulkan1 libevent-dev \
  libflac-dev libsdl2-dev \
  libgtk-4-dev libadwaita-1-dev libgtk4-layer-shell-dev \
  libapr1-dev libaprutil1-dev libglib2.0-dev libc6-dbg \
  libsoup-3.0-dev libjavascriptcoregtk-4.1-dev libwebkit2gtk-4.1-dev \
  libx11-dev libudev-dev libxkbcommon-x11-0
