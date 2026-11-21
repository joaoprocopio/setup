#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# 26.1.4 and later fail under Wine's crypt32, https://bugs.winehq.org/show_bug.cgi?id=60273
FL_VERSION="26.1.3.5570"
FL_SHA256="bd8f4f791a4ae5bf341c914aab279caa2f6cfd0b47f692c714f34de997ea20c5"

# Kron4ek's wow64 Wine 11.0, because FL's WebView2 panels render black in Debian's Wine 10.0.
WINE_VERSION="11.0"
WINE_NAME="wine-$WINE_VERSION-amd64-wow64"
WINE_SHA256="39574efa1132c3ca0d5c77dd2eddbe4a49cca0d6cc2c290ff4924493a1c40314"

# Debian's winetricks package depends on Debian's wine.
WINETRICKS_VERSION="20250102"
WINETRICKS_SHA256="53194dead910f8a5eb1deacaa4773d4e48f5873633d18ab1ecd6fdb0cb92243b"

if is_admin; then
  # The Wine tarball links against these host libraries without bundling them.
  apt_install cabextract icoutils fonts-ipafont-gothic \
    libfreetype6 libfontconfig1 libgnutls30t64 libpulse0 libasound2t64 \
    libvulkan1 libgl1 libxrandr2 libxi6 libxcursor1 libxinerama1 libxcomposite1 \
    libxkbcommon0 libwayland-client0 libdbus-1-3 libgstreamer-plugins-base1.0-0 \
    libsdl2-2.0-0 libcups2t64 libkrb5-3
fi

WINE_DIR="$HOME/.local/$WINE_NAME"
export WINEPREFIX="$HOME/.wine-fl"
export PATH="$WINE_DIR/bin:$PATH"
# Wine's menu entries call a wine that is not on PATH, so the step writes its own launcher.
export WINEDLLOVERRIDES="winemenubuilder.exe=d"

cd "$WORK" || exit

curl -#fSLO "https://github.com/Kron4ek/Wine-Builds/releases/download/$WINE_VERSION/$WINE_NAME.tar.xz"
echo "$WINE_SHA256  $WINE_NAME.tar.xz" | sha256sum -c
rm -rf "$WINE_DIR"
tar -xf "$WINE_NAME.tar.xz" -C "$(dirname "$WINE_DIR")"

curl -fsSL "https://raw.githubusercontent.com/Winetricks/winetricks/$WINETRICKS_VERSION/src/winetricks" -o winetricks
echo "$WINETRICKS_SHA256  winetricks" | sha256sum -c

# The overrides skip the Mono and Gecko prompts, which FL never uses.
WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mscoree,mshtml=" wineboot --init
bash winetricks -q corefonts
# FL draws sharps and flats with MS Gothic, and IPAGothic has both glyphs.
wine reg add 'HKCU\Software\Wine\Fonts\Replacements' /v 'MS Gothic' /d IPAGothic /f
wine reg add 'HKCU\Software\Wine\Fonts\Replacements' /v 'MS PGothic' /d IPAPGothic /f

curl -#fSL "https://install.image-line.com/flstudio/flstudio_win64_$FL_VERSION.exe" -o flstudio.exe
echo "$FL_SHA256  flstudio.exe" | sha256sum -c
# The installer exits 199 after a complete install, so the check below looks for FL64.exe instead.
wine flstudio.exe /S || true
# The WebView2 installer leaves Edge's updater running forever.
wineserver --kill

FL_EXE="$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio 2026/FL64.exe"
if [ ! -f "$FL_EXE" ]; then
  echo "the installer finished without creating $FL_EXE" >&2
  exit 1
fi

# fl-wine runs FL's Wine in FL's prefix, for plugin installers.
cat >"$HOME/.local/bin/fl-wine" <<EOF
#!/bin/sh
export WINEPREFIX="$WINEPREFIX"
export WINEDLLOVERRIDES="$WINEDLLOVERRIDES"
exec "$WINE_DIR/bin/wine" "\$@"
EOF
cat >"$HOME/.local/bin/fl-studio" <<EOF
#!/bin/sh
exec "$HOME/.local/bin/fl-wine" "$FL_EXE" "\$@"
EOF
chmod +x "$HOME/.local/bin/fl-wine" "$HOME/.local/bin/fl-studio"

ICON="$HOME/.local/share/icons/hicolor/256x256/apps/fl-studio.png"
mkdir -p "$(dirname "$ICON")" "$HOME/.local/share/applications" "$HOME/.config"
wrestool -x -t 14 "$FL_EXE" >fl.ico
icotool -x -w 256 -h 256 -o "$ICON" fl.ico

# The browser login ends on a flstudio:// link, which opens the app registered for that scheme.
cat >"$HOME/.local/share/applications/fl-studio.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=FL Studio
Exec=$HOME/.local/bin/fl-studio %u
Icon=fl-studio
StartupWMClass=fl64.exe
MimeType=x-scheme-handler/flstudio;
Categories=AudioVideo;Audio;
EOF
xdg-mime default fl-studio.desktop x-scheme-handler/flstudio

note "open FL Studio, log in to your Image-Line account, and pick the FL Studio ASIO driver in Options > Audio settings"
note "decline the FL Studio update: 26.1.4 and later do not start under Wine"
