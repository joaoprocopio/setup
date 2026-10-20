#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

apt_install \
  dconf-editor gnome-tweaks gnome-shell-extensions \
  gnome-shell-extension-appindicator \
  gnome-shell-extension-desktop-icons-ng \
  gnome-shell-extension-tiling-assistant \
  gnome-shell-extension-caffeine \
  fonts-inter fonts-jetbrains-mono

# Extensions
# Quick Settings Audio Panel não tem pacote no Debian, então vem do extensions.gnome.org
# Ela mostra o slider do microfone mesmo quando nenhum app usa o microfone
GNOME_VERSION="$(gnome-shell --version | grep -o '[0-9]*' | head -1)"
curl -fsSL "https://extensions.gnome.org/download-extension/quick-settings-audio-panel@rayzeq.github.io.shell-extension.zip?shell_version=$GNOME_VERSION" -o "$WORK/qsap.zip"
gnome-extensions install --force "$WORK/qsap.zip"
# Só as chaves que diferem do default do schema da extensão
QSAP=/org/gnome/shell/extensions/quick-settings-audio-panel
dconf write $QSAP/panel-type "'merged-panel'"
dconf write $QSAP/merged-panel-position "'top'"
dconf write $QSAP/always-show-input-volume-slider true
dconf write $QSAP/autohide-profile-switcher false
dconf write $QSAP/create-applications-volume-sliders false
dconf write $QSAP/widgets-order "[
  'mpris-controllers',
  'input-volume-slider',
  'output-volume-slider',
  'profile-switcher',
  'perdevice-volume-sliders',
  'balance-slider',
  'applications-volume-sliders'
]"

# Desktop Icons NG e Tiling Assistant são as mesmas extensões que o Ubuntu liga por padrão
# Escrito direto no gsettings pq o gnome-extensions só enxerga extensões novas depois de relogar
gsettings set org.gnome.shell disable-user-extensions false
# O GNOME ignora em enabled-extensions todo UUID que também está em disabled-extensions
gsettings set org.gnome.shell disabled-extensions "[]"
gsettings set org.gnome.shell enabled-extensions "[
  'ubuntu-appindicators@ubuntu.com',
  'user-theme@gnome-shell-extensions.gcampax.github.com',
  'native-window-placement@gnome-shell-extensions.gcampax.github.com',
  'drive-menu@gnome-shell-extensions.gcampax.github.com',
  'ding@rastersoft.com',
  'tiling-assistant@leleat-on-github',
  'caffeine@patapon.info',
  'quick-settings-audio-panel@rayzeq.github.io'
]"
note "saia da sessão e entre de novo para o GNOME carregar as extensões"

# Dark Mode
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

# Animações
gsettings set org.gnome.desktop.interface enable-animations false

# Hot Corner
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Workspaces: número fixo de 1, em todas as telas
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1
gsettings set org.gnome.mutter workspaces-only-on-primary false

# Fontes
gsettings set org.gnome.desktop.interface font-name "Inter 11"
gsettings set org.gnome.desktop.interface document-font-name "Inter 11"
gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 11"
gsettings set org.gnome.desktop.wm.preferences titlebar-font "Inter Bold 11"

# Tweaks > Windows > Titlebar Buttons > Maximize + Minimize
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"

# Compose Key no Right Alt
gsettings set org.gnome.desktop.input-sources xkb-options "['compose:ralt']"

# Switch Windows com ALT + TAB
gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"

# Custom Keybindings
KEYBINDING=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KEYBINDING']"

# Keybind 0: terminal (o passo ghostty instala o binário)
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEYBINDING" binding "<Control><Alt>t"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEYBINDING" command "$HOME/.local/bin/ghostty"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEYBINDING" name "Open Terminal"
