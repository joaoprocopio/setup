# Which account runs the scripts, sourced by install.sh and lib.sh.
#
# The admin account is in the sudo group: it installs what is machine-wide
# (apt, /etc, /usr/local, services) and also sets up its own home. Any other
# account has no sudo at all and only sets up its own home, on top of what the
# admin account installed. ADMIN is 1 for the first and empty for the second.
#
# $PROFILE_FILE says which profile this account is (pessoal or trabalho) and
# holds the git identity. It stays out of the repository, which is public.

# shellcheck shell=bash disable=SC2034
PROFILE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/tools/profile"

# The group database, not the session: an account added to sudo counts before
# its next login, and no sudo call is needed to find out.
ADMIN=
case " $(id -nG "$(id -un)") " in
  *" sudo "*) ADMIN=1 ;;
esac

if [ -f "$PROFILE_FILE" ]; then
  # shellcheck source=/dev/null
  . "$PROFILE_FILE"
fi
