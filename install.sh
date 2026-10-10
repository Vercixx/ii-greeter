#!/usr/bin/env bash
# this script also supports uninstall: ./install uninstall
set -euo pipefail

SHARE=/usr/local/share/ii-greeter
BIN=/usr/local/bin
DATA=/var/lib/ii-greeter
FONTS=/usr/local/share/fonts/illogical-impulse-google-sans-flex
GREETD_CONF=/etc/greetd/config.toml
BACKUP=$GREETD_CONF.ii-greeter.bak
SRC=$(dirname "$(readlink -f "$0")")

die() {
    echo "$*" >&2
    exit 1
}

toml_get() {
    [[ -f $GREETD_CONF ]] || return 0
    awk -v section="[$1]" -v key="$2" '
        /^[[:space:]]*\[/ { gsub(/[[:space:]]/, ""); inside = ($0 == section); next }
        inside {
            k = $0; sub(/=.*/, "", k); gsub(/[[:space:]]/, "", k)
            if (k == key) { sub(/^[^=]*=[[:space:]]*/, ""); gsub(/^"|"[[:space:]]*$/, ""); print; exit }
        }' "$GREETD_CONF"
}

[[ ${BASH_SOURCE[0]} == "$0" ]] || return 0
[[ $EUID -eq 0 ]] || die "Run with pkexec or sudo."

if [[ ${1:-} == uninstall ]]; then
    [[ -f $BACKUP ]] && mv -f "$BACKUP" "$GREETD_CONF"
    rm -rf "$SHARE" "$DATA" "$FONTS" "$BIN/ii-greeter-session" "$BIN/ii-greeter-sync"
    echo "Greeter removed, previous greetd config restored."
    exit 0
fi

uid=${PKEXEC_UID:-${SUDO_UID:-}}
[[ -n $uid ]] || die "Could not detect the calling user."
IFS=: read -r user _ _ _ _ home _ < <(getent passwd "$uid") || die "Unknown uid $uid."

for cmd in greetd agreety Hyprland qs; do
    command -v "$cmd" >/dev/null || die "Missing $cmd. Install it with your package manager first."
done

[[ -f $SRC/modules/common/widgets/shapes/ShapeCanvas.qml ]] \
    || die "Missing shapes submodule in $SRC. Clone with --recurse-submodules or run: git submodule update --init --recursive"

greeter_user=$(toml_get default_session user)
greeter_user=${greeter_user:-greeter}
getent passwd "$greeter_user" >/dev/null || die "greetd user '$greeter_user' does not exist."
greeter_group=$(id -gn "$greeter_user")
vt=$(toml_get terminal vt)
vt=${vt:-1}
[[ $vt =~ ^[0-9]+$ ]] || vt="\"$vt\""

rm -rf "$SHARE"
mkdir -p "$SHARE"
tar -C "$SRC" --exclude=.git -cf - . | tar -C "$SHARE" --no-same-owner -xf -
chmod -R u=rwX,go=rX "$SHARE"
install -m755 "$SRC/ii-greeter-session" "$SRC/ii-greeter-sync" "$BIN/"

user_fonts="$home/.local/share/fonts/illogical-impulse-google-sans-flex"
if [[ -d $user_fonts ]]; then
    rm -rf "$FONTS"
    mkdir -p "$FONTS"
    cp -rT "$user_fonts" "$FONTS"
    chmod -R u=rwX,go=rX "$FONTS"
    fc-cache -f "$FONTS" >/dev/null 2>&1 || true
fi

install -d -m755 "$DATA" "$DATA/users"
install -d -m750 -o "$greeter_user" -g "$greeter_group" "$DATA/state"
install -d -m700 -o "$greeter_user" -g "$greeter_group" "$DATA/state/cache"
install -d -m2750 -o "$user" -g "$greeter_group" "$DATA/users/$user"

mkdir -p "$(dirname "$GREETD_CONF")"
[[ -f $GREETD_CONF && ! -f $BACKUP ]] && cp -p "$GREETD_CONF" "$BACKUP"
cat > "$GREETD_CONF" <<EOF
[terminal]
vt = $vt

[default_session]
command = "$BIN/ii-greeter-session"
user = "$greeter_user"
EOF

runuser -u "$user" -- env HOME="$home" "$BIN/ii-greeter-sync" || true

echo "Greeter installed. Enable the greetd service and disable your current display manager to use it."
