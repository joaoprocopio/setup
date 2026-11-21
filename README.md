# tools

Installs and configures a Debian machine for two Linux accounts: an admin account that has sudo, and a second account that never calls sudo.

## Set up a new machine

1. Install Debian with LUKS, and leave the root password empty, so the first account joins the `sudo` group.
2. In that account, run `sudo apt install git`, clone `https://github.com/joaoprocopio/setup.git`, and run `./src/install.sh --admin`. It installs machine-wide software and sets up that account's home.
3. Create the second account: `sudo adduser --shell /usr/bin/zsh account_name`.
4. Log in to the second account from the login screen, not with `su`, because rootless Docker and the GNOME settings need its own session.
5. In the second account, clone the repository and run `./src/install.sh --no-admin`. It sets up that account's home only.

On its first run in each account, the git step asks for your git name and email.

After you change a step, pull the change in both clones and run `./src/install.sh --admin` first. Until then, `./src/install.sh --no-admin --list` shows a step that calls `is_admin` as `waiting`, because `--no-admin` runs that step only after `--admin` has run the same version of it. A step without `is_admin` has no machine-wide part, so `--no-admin` runs it whether or not `--admin` has.

## Skip steps you do not want

To skip a step in one account, list it in `.setupignore` at the root of that account's clone. Each clone has its own file, and git ignores it. Write one step per line as `name` or `NNNN-name`, and start a comment with `#`:

```text
# no games on this machine
prismlauncher
0240-flstudio
```

When you run `install.sh` without step names, it skips the listed steps, and `--list` shows them as `ignored`. A step you name on the command line still runs. An unknown name in the file stops `install.sh` with the file and line number.

If the admin account ignores a step that calls `is_admin`, the second account cannot run that step either, because the machine-wide part it needs is missing. `install.sh --no-admin` then fails that step with `run src/install.sh --admin name first`. A step without `is_admin` stays independent in each account.
