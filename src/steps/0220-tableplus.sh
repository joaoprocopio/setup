#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://tableplus.com/blog/2019/10/tableplus-linux-installation.html
apt_source tableplus https://deb.tableplus.com/apt.tableplus.com.gpg.key https://deb.tableplus.com/debian/24 tableplus main
apt_install tableplus
