#!/usr/bin/env bash
set -euo pipefail

MARK_BEGIN='# >>> kurenai >>>'
MARK_END='# <<< kurenai <<<'

die() {
  printf 'uninstall.sh: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
uninstall.sh - desinstala kurenai

uso: uninstall.sh [opciones]

  --prefix DIR     directorio donde se instaló (por defecto: ~/.local/bin)
  --bashrc FILE    archivo de configuración (por defecto: ~/.bashrc)
  --keep-cache     conserva la caché de la IP pública
  -h, --help       muestra esta ayuda
EOF
}

if [[ ${EUID:-$(id -u)} -eq 0 && -n ${SUDO_USER:-} && ${SUDO_USER:-} != root ]]; then
  if command -v getent >/dev/null 2>&1; then
    target_home=$(getent passwd "$SUDO_USER" | cut -d: -f6) || target_home=''
  else
    target_home=$(eval echo "~$SUDO_USER")
  fi
  [[ -n $target_home ]] || die "no se pudo obtener el HOME de $SUDO_USER"
  script_path=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")
  [[ -f $script_path ]] || die 'ejecuta uninstall.sh desde un archivo, no por pipe'
  exec sudo -u "$SUDO_USER" env \
    HOME="$target_home" USER="$SUDO_USER" LOGNAME="$SUDO_USER" \
    PREFIX="${PREFIX:-}" BASHRC="${BASHRC:-}" XDG_CACHE_HOME="${XDG_CACHE_HOME:-}" \
    bash "$script_path" "$@"
fi

: "${HOME:?uninstall.sh: HOME no está definido}"

PREFIX=${PREFIX:-"$HOME/.local/bin"}
BASHRC=${BASHRC:-"$HOME/.bashrc"}
KEEP_CACHE=0

while (( $# )); do
  case $1 in
    --prefix)
      [[ $# -ge 2 ]] || die '--prefix necesita un valor'
      PREFIX=$2
      shift 2 ;;
    --bashrc)
      [[ $# -ge 2 ]] || die '--bashrc necesita un valor'
      BASHRC=$2
      shift 2 ;;
    --keep-cache) KEEP_CACHE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

[[ $PREFIX == /* ]] || die 'PREFIX debe ser una ruta absoluta'
[[ $BASHRC == /* ]] || die 'BASHRC debe ser una ruta absoluta'

CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/kurenai
BIN=$PREFIX/kurenai

if [[ -L $BASHRC ]]; then
  BASHRC=$(readlink -f -- "$BASHRC") || die "no se pudo resolver $BASHRC"
fi

tmp=''
cleanup() {
  [[ -n $tmp ]] && rm -f -- "$tmp"
  return 0
}
trap cleanup EXIT

if [[ -f $BASHRC ]] && grep -qF -- "$MARK_BEGIN" "$BASHRC" && ! grep -qF -- "$MARK_END" "$BASHRC"; then
  die "el bloque kurenai de $BASHRC está mal formado; edítalo a mano"
fi
if [[ -f $BASHRC ]] && ! grep -qF -- "$MARK_BEGIN" "$BASHRC" && grep -qF -- "$MARK_END" "$BASHRC"; then
  die "el bloque kurenai de $BASHRC está mal formado; edítalo a mano"
fi

if [[ -f $BASHRC ]] && grep -qF -- "$MARK_BEGIN" "$BASHRC" && grep -qF -- "$MARK_END" "$BASHRC"; then
  begin_line=$(grep -nF -m1 -- "$MARK_BEGIN" "$BASHRC" | cut -d: -f1)
  end_line=$(grep -nF -m1 -- "$MARK_END" "$BASHRC" | cut -d: -f1)
  if [[ -z $begin_line || -z $end_line || $begin_line -ge $end_line ]]; then
    die "el bloque kurenai de $BASHRC está mal formado; edítalo a mano"
  fi

  tmp=$(mktemp "${BASHRC}.kurenai.XXXXXX") || die "no se pudo crear un temporal para $BASHRC"
  awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$BASHRC" > "$tmp"
  chmod --reference="$BASHRC" "$tmp" || die "no se pudo conservar los permisos de $BASHRC"
  mv -f -- "$tmp" "$BASHRC" || die "no se pudo actualizar $BASHRC"
  tmp=''
  printf 'kurenai: bloque eliminado de %s\n' "$BASHRC"
else
  printf 'kurenai: no hay bloque que eliminar en %s\n' "$BASHRC"
fi

if [[ -f $BIN || -L $BIN ]]; then
  rm -f -- "$BIN"
  printf 'kurenai: eliminado %s\n' "$BIN"
elif [[ -e $BIN ]]; then
  printf 'uninstall.sh: %s existe pero no es un archivo; no se eliminó\n' "$BIN" >&2
else
  printf 'kurenai: no existe %s\n' "$BIN"
fi

if (( KEEP_CACHE )); then
  printf 'kurenai: caché conservada en %s\n' "$CACHE_DIR"
elif [[ -d $CACHE_DIR ]]; then
  rm -rf -- "$CACHE_DIR"
  printf 'kurenai: caché eliminada (%s)\n' "$CACHE_DIR"
fi
