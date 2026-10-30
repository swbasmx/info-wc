#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'uninstall.sh: %s\n' "$*" >&2
  exit 1
}

if [[ ${EUID:-$(id -u)} -eq 0 && -n ${SUDO_USER:-} && ${SUDO_USER:-} != root ]]; then
  target_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  [[ -n $target_home ]] || die "no se pudo obtener el HOME de $SUDO_USER"
  script_path=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")
  exec sudo -u "$SUDO_USER" env HOME="$target_home" USER="$SUDO_USER" LOGNAME="$SUDO_USER" bash "$script_path" "$@"
fi

: "${HOME:?uninstall.sh: HOME no está definido}"

PREFIX=${PREFIX:-"$HOME/.local/bin"}
BASHRC=${BASHRC:-"$HOME/.bashrc"}
BIN=$PREFIX/info-wc
MARK_BEGIN='# >>> info-wc >>>'
MARK_END='# <<< info-wc <<<'

[[ $PREFIX == /* ]] || die 'PREFIX debe ser una ruta absoluta'
[[ $BASHRC == /* ]] || die 'BASHRC debe ser una ruta absoluta'

if [[ -L $BASHRC ]]; then
  BASHRC=$(readlink -f -- "$BASHRC") || die "no se pudo resolver $BASHRC"
fi

tmp=''
cleanup() {
  [[ -n $tmp ]] && rm -f -- "$tmp"
}
trap cleanup EXIT

if [[ -f $BASHRC ]] && grep -qF -- "$MARK_BEGIN" "$BASHRC" && grep -qF -- "$MARK_END" "$BASHRC"; then
  begin_line=$(grep -nF -m1 -- "$MARK_BEGIN" "$BASHRC" | cut -d: -f1)
  end_line=$(grep -nF -m1 -- "$MARK_END" "$BASHRC" | cut -d: -f1)
  if [[ -z $begin_line || -z $end_line || $begin_line -ge $end_line ]]; then
    die "el bloque info-wc de $BASHRC está mal formado; edítalo a mano"
  fi

  tmp=$(mktemp "${BASHRC}.info-wc.XXXXXX")
  awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$BASHRC" > "$tmp"
  chmod --reference="$BASHRC" "$tmp"
  mv -f -- "$tmp" "$BASHRC"
  tmp=''
  printf 'info-wc: bloque eliminado de %s\n' "$BASHRC"
else
  printf 'info-wc: no hay bloque que eliminar en %s\n' "$BASHRC"
fi

if [[ -f $BIN || -L $BIN ]]; then
  rm -f -- "$BIN"
  printf 'info-wc: eliminado %s\n' "$BIN"
elif [[ -e $BIN ]]; then
  printf 'uninstall.sh: %s existe pero no es un archivo; no se eliminó\n' "$BIN" >&2
else
  printf 'info-wc: no existe %s\n' "$BIN"
fi
