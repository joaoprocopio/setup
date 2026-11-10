#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://github.com/neovim/neovim/blob/master/BUILD.md
apt_install ninja-build gettext cmake unzip curl build-essential

git clone -b stable --depth 1 https://github.com/neovim/neovim "$WORK/neovim"
make -C "$WORK/neovim" CMAKE_BUILD_TYPE=Release
sudo make -C "$WORK/neovim" install
# make install leaves root-owned files in the build tree.
sudo rm -rf "$WORK/neovim"
sudo ln -sf /usr/local/bin/nvim /usr/local/bin/vim

# kickstart.nvim, only when there is no config yet, so yours is never replaced.
if [ ! -d ~/.config/nvim ]; then
  git clone --depth 1 https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
fi
