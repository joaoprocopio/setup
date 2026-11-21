# tools

Installs and configures a Debian machine for two Linux accounts: an admin account that has sudo, and a second account that never calls sudo.

## Set up a new machine

1. Install Debian with LUKS, and leave the root password empty, so the first account joins the `sudo` group.
2. In that account, run `sudo apt install git`, clone `https://github.com/joaoprocopio/setup.git`, and run `./src/install.sh --admin`. It installs machine-wide software and sets up that account's home.
3. Create the second account: `sudo adduser --shell /usr/bin/zsh account_name`.
4. Log in to the second account from the login screen, not with `su`, because rootless Docker and the GNOME settings need its own session.
5. In the second account, clone the repository and run `./src/install.sh --no-admin`. It sets up that account's home only.

On its first run in each account, the git step asks for your git name and email.

After you change a step, run `./src/install.sh --admin` first. Until then, `./src/install.sh --no-admin --list` shows the step as `waiting`.
