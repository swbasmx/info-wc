#!/usr/bin/env bash
set -euo pipefail

: "${HOME:?install.sh: HOME no está definido}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PREFIX=${PREFIX:-"$HOME/.local/bin"}
BASHRC=${BASHRC:-"$HOME/.bashrc"}
SRC=$SCRIPT_DIR/info-wc
BIN=$PREFIX/info-wc
MARK_BEGIN='# >>> info-wc >>>'
MARK_END='# <<< info-wc <<<'

die() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}

[[ $PREFIX == /* ]] || die 'PREFIX debe ser una ruta absoluta'
[[ $BASHRC == /* ]] || die 'BASHRC debe ser una ruta absoluta'
[[ -f $SRC ]] || die "no se encontró $SRC"
[[ -s $SRC ]] || die "$SRC está vacío"

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
