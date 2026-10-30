#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}

if [[ ${EUID:-$(id -u)} -eq 0 && -n ${SUDO_USER:-} && ${SUDO_USER:-} != root ]]; then
  target_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  [[ -n $target_home ]] || die "no se pudo obtener el HOME de $SUDO_USER"
  script_path=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")
  exec sudo -u "$SUDO_USER" env HOME="$target_home" USER="$SUDO_USER" LOGNAME="$SUDO_USER" bash "$script_path" "$@"
fi

: "${HOME:?install.sh: HOME no está definido}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PREFIX=${PREFIX:-"$HOME/.local/bin"}
BASHRC=${BASHRC:-"$HOME/.bashrc"}
SRC=$SCRIPT_DIR/info-wc
BIN=$PREFIX/info-wc
MARK_BEGIN='# >>> info-wc >>>'
MARK_END='# <<< info-wc <<<'
REPO_RAW=${REPO_RAW:-https://raw.githubusercontent.com/swbasmx/info-wc/main/info-wc}

tmp_src=''
cleanup() {
  if [[ -n $tmp_src ]]; then
    rm -f -- "$tmp_src"
  fi
  return 0
}
trap cleanup EXIT

[[ $PREFIX == /* ]] || die 'PREFIX debe ser una ruta absoluta'
[[ $BASHRC == /* ]] || die 'BASHRC debe ser una ruta absoluta'
if [[ ! -f $SRC ]]; then
  if command -v curl >/dev/null 2>&1; then
    tmp_src=$(mktemp)
    curl -fsSL -o "$tmp_src" -- "$REPO_RAW" || die "no se pudo descargar $REPO_RAW"
    SRC=$tmp_src
  elif command -v wget >/dev/null 2>&1; then
    tmp_src=$(mktemp)
    wget -qO "$tmp_src" -- "$REPO_RAW" || die "no se pudo descargar $REPO_RAW"
    SRC=$tmp_src
  else
    die 'se necesita curl o wget para descargar info-wc'
  fi
fi
[[ -s $SRC ]] || die "no se pudo obtener info-wc"

if [[ -L $BASHRC ]]; then
  BASHRC=$(readlink -f -- "$BASHRC") || die "no se pudo resolver $BASHRC"
fi

install -d -m 755 -- "$PREFIX"
install -m 755 -- "$SRC" "$BIN"

if grep -qF -- "$MARK_BEGIN" "$BASHRC" 2>/dev/null; then
  printf 'info-wc: el bloque ya existe en %s; no se duplicó.\n' "$BASHRC"
else
  [[ -e $BASHRC ]] || : > "$BASHRC"
  if [[ -s $BASHRC ]] && [[ $(tail -c 1 -- "$BASHRC" | wc -l) -eq 0 ]]; then
    printf '\n' >> "$BASHRC"
  fi
  {
    printf '%s\n' "$MARK_BEGIN"
    printf 'if [[ $- == *i* && -x %q ]]; then\n' "$BIN"
    printf '  %q\n' "$BIN"
    printf '%s\n' 'fi'
    printf '%s\n' "$MARK_END"
  } >> "$BASHRC"
  printf 'info-wc: bloque añadido a %s; se ejecutará al abrir una terminal interactiva.\n' "$BASHRC"
fi

printf 'info-wc instalado en %s\n' "$BIN"
printf 'Abre una terminal nueva o ejecuta: source %s\n' "$BASHRC"
