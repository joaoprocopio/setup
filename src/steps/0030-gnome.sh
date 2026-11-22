#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  apt_install \
    dconf-editor gnome-tweaks gnome-shell-extensions \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-desktop-icons-ng \
    gnome-shell-extension-tiling-assistant \
    fonts-inter fonts-jetbrains-mono

  # With linger on, this account's PipeWire starts at boot and fights GDM's PipeWire for the sound card.
  sudo loginctl disable-linger "$USER"
fi

# Quick Settings Audio Panel has no Debian package. It shows the microphone slider even when no app uses the microphone.
GNOME_VERSION="$(gnome-shell --version | grep -o '[0-9]*' | head -1)"
curl -fsSL "https://extensions.gnome.org/download-extension/quick-settings-audio-panel@rayzeq.github.io.shell-extension.zip?shell_version=$GNOME_VERSION" -o "$WORK/qsap.zip"
gnome-extensions install --force "$WORK/qsap.zip"
# Only the keys that differ from the extension's schema defaults.
QSAP=/org/gnome/shell/extensions/quick-settings-audio-panel
dconf write $QSAP/panel-type "'merged-panel'"
dconf write $QSAP/merged-panel-position "'top'"
dconf write $QSAP/always-show-input-volume-slider true
dconf write $QSAP/autohide-profile-switcher false
dconf write $QSAP/create-applications-volume-sliders false
# Shows media, speaker, and microphone from top to bottom, because 'top' inserts each widget at grid index 2.
dconf write $QSAP/widgets-order "[
  'output-volume-slider',
  'mpris-controllers',
  'input-volume-slider'
]"

# gsettings, because gnome-extensions sees a new extension only after the next login.
gsettings set org.gnome.shell disable-user-extensions false
# GNOME ignores an enabled UUID that is also in disabled-extensions.
gsettings set org.gnome.shell disabled-extensions "[]"
gsettings set org.gnome.shell enabled-extensions "[
  'ubuntu-appindicators@ubuntu.com',
  'user-theme@gnome-shell-extensions.gcampax.github.com',
  'native-window-placement@gnome-shell-extensions.gcampax.github.com',
  'drive-menu@gnome-shell-extensions.gcampax.github.com',
  'ding@rastersoft.com',
  'tiling-assistant@leleat-on-github',
  'quick-settings-audio-panel@rayzeq.github.io'
]"
note "log out and back in to load the GNOME extensions"

# Dark mode
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"

# Animations
gsettings set org.gnome.desktop.interface enable-animations false

# Hot corner
gsettings set org.gnome.desktop.interface enable-hot-corners false

# One fixed workspace, on every screen
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1
gsettings set org.gnome.mutter workspaces-only-on-primary false

# Fonts
gsettings set org.gnome.desktop.interface font-name "Inter 11"
gsettings set org.gnome.desktop.interface document-font-name "Inter 11"
gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 11"
gsettings set org.gnome.desktop.wm.preferences titlebar-font "Inter Bold 11"

# Tweaks > Windows > Titlebar Buttons > Maximize + Minimize
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"

# Touchpad > Disable Touchpad While Typing off
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false

# Touchpad > Scroll Direction > Traditional
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

# Mouse & Touchpad > Pointer Speed 0
gsettings set org.gnome.desktop.peripherals.mouse speed 0
gsettings set org.gnome.desktop.peripherals.touchpad speed 0

# Keyboard > Input Sources: English (US) and Portuguese (Brazil)
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'br')]"

# Compose key on Right Alt
gsettings set org.gnome.desktop.input-sources xkb-options "['compose:ralt']"

# Alt+Tab switches windows, not applications
gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"

# Ctrl+Alt+T opens the Ghostty that the ghostty step builds
KEYBINDING=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KEYBINDING']"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEYBINDING" binding "<Control><Alt>t"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEYBINDING" command "$HOME/.local/bin/ghostty"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEYBINDING" name "Open Terminal"
