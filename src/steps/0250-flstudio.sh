#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Every version below is pinned, so FL Studio and its Wine change only when
# this file does.
#
# FL Studio 26.1.4 and later refuse to start under Wine, because Wine's
# crypt32 rejects their signature (https://bugs.winehq.org/show_bug.cgi?id=60273).
# FL stays on 26.1.3 until a Wine release has the fix.
FL_VERSION="26.1.3.5570"
FL_SHA256="bd8f4f791a4ae5bf341c914aab279caa2f6cfd0b47f692c714f34de997ea20c5"

# Kron4ek's build of the stable Wine 11.0. Debian ships Wine 10.0, where
# FL's WebView2 panels (Gopher, Help, FL Cloud) render black. The wow64
# build runs 32-bit programs, such as FL's installer, without i386 packages.
WINE_VERSION="11.0"
WINE_NAME="wine-$WINE_VERSION-amd64-wow64"
WINE_SHA256="39574efa1132c3ca0d5c77dd2eddbe4a49cca0d6cc2c290ff4924493a1c40314"

# Debian's winetricks package depends on Debian's wine, so the step fetches
# the script itself.
WINETRICKS_VERSION="20250102"
WINETRICKS_SHA256="53194dead910f8a5eb1deacaa4773d4e48f5873633d18ab1ecd6fdb0cb92243b"

WINE_DIR="$HOME/.local/opt/$WINE_NAME"
export WINEPREFIX="$HOME/.wine-fl"
export PATH="$WINE_DIR/bin:$PATH"
# Wine's own menu entries call a wine that is not on PATH, so the step
# turns them off and writes its own launcher.
export WINEDLLOVERRIDES="winemenubuilder.exe=d"

# The Wine tarball links against these host libraries without bundling them.
apt_install cabextract icoutils fonts-ipafont-gothic \
  libfreetype6 libfontconfig1 libgnutls30t64 libpulse0 libasound2t64 \
  libvulkan1 libgl1 libxrandr2 libxi6 libxcursor1 libxinerama1 libxcomposite1 \
  libxkbcommon0 libwayland-client0 libdbus-1-3 libgstreamer-plugins-base1.0-0 \
  libsdl2-2.0-0 libcups2t64 libkrb5-3

cd "$WORK"

curl -#fSLO "https://github.com/Kron4ek/Wine-Builds/releases/download/$WINE_VERSION/$WINE_NAME.tar.xz"
echo "$WINE_SHA256  $WINE_NAME.tar.xz" | sha256sum -c
rm -rf "$WINE_DIR"
mkdir -p "$(dirname "$WINE_DIR")"
tar -xf "$WINE_NAME.tar.xz" -C "$(dirname "$WINE_DIR")"

curl -fsSL "https://raw.githubusercontent.com/Winetricks/winetricks/$WINETRICKS_VERSION/src/winetricks" -o winetricks
echo "$WINETRICKS_SHA256  winetricks" | sha256sum -c

# A prefix of its own keeps other Windows programs from changing FL's DLLs.
# The overrides skip the Mono and Gecko download prompts, which FL never uses.
WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mscoree,mshtml=" wineboot --init
bash winetricks -q corefonts
# FL draws sharps and flats with MS Gothic, and IPAGothic has both glyphs.
wine reg add 'HKCU\Software\Wine\Fonts\Replacements' /v 'MS Gothic' /d IPAGothic /f
wine reg add 'HKCU\Software\Wine\Fonts\Replacements' /v 'MS PGothic' /d IPAPGothic /f

curl -#fSL "https://install.image-line.com/flstudio/flstudio_win64_$FL_VERSION.exe" -o flstudio.exe
echo "$FL_SHA256  flstudio.exe" | sha256sum -c
# The installer exited with 199 after a complete install, so the check
# below looks for FL64.exe in place of the exit code.
wine flstudio.exe /S || true
# The WebView2 installer leaves Edge's updater running, and it never exits.
wineserver --kill

FL_EXE="$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio 2026/FL64.exe"
if [ ! -f "$FL_EXE" ]; then
  echo "o instalador terminou sem criar $FL_EXE" >&2
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

# The login in the browser ends on a flstudio:// link, and the browser
# opens it with the app registered for x-scheme-handler/flstudio.
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

note "abra o FL Studio, entre na conta da Image-Line e escolha o driver FL Studio ASIO em Options > Audio settings"
note "recuse a atualização do FL Studio: a versão 26.1.4 e as seguintes não abrem no Wine"
