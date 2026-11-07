#!/usr/bin/env bash
set -euo pipefail

MARK_BEGIN='# >>> kurenai >>>'
MARK_END='# <<< kurenai <<<'

die() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
install.sh - instala kurenai y su autoarranque

uso: install.sh [opciones]

  --prefix DIR     directorio de instalación (por defecto: ~/.local/bin)
  --bashrc FILE    archivo de configuración (por defecto: ~/.bashrc)
  --no-autostart   instala el comando pero no lo ejecuta al abrir la terminal
  --repo URL       URL alternativa de kurenai
  -h, --help       muestra esta ayuda

También puedes usar PREFIX, BASHRC y REPO_RAW como variables de entorno.
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
  [[ -f $script_path ]] || die 'ejecuta install.sh desde un archivo, no por pipe'
  exec sudo -u "$SUDO_USER" env \
    HOME="$target_home" USER="$SUDO_USER" LOGNAME="$SUDO_USER" \
    PREFIX="${PREFIX:-}" BASHRC="${BASHRC:-}" REPO_RAW="${REPO_RAW:-}" \
    bash "$script_path" "$@"
fi

: "${HOME:?install.sh: HOME no está definido}"

PREFIX=${PREFIX:-"$HOME/.local/bin"}
BASHRC=${BASHRC:-"$HOME/.bashrc"}
REPO_RAW=${REPO_RAW:-https://raw.githubusercontent.com/swbasmx/kurenai/main/kurenai}
AUTOSTART=1

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
    --repo)
      [[ $# -ge 2 ]] || die '--repo necesita un valor'
      REPO_RAW=$2
      shift 2 ;;
    --no-autostart) AUTOSTART=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

[[ $PREFIX == /* ]] || die 'PREFIX debe ser una ruta absoluta'
[[ $BASHRC == /* ]] || die 'BASHRC debe ser una ruta absoluta'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SRC=$SCRIPT_DIR/kurenai
BIN=$PREFIX/kurenai

tmp_src=''
tmp_bashrc=''
cleanup() {
  [[ -n $tmp_src ]] && rm -f -- "$tmp_src"
  [[ -n $tmp_bashrc ]] && rm -f -- "$tmp_bashrc"
  return 0
}
trap cleanup EXIT

if [[ ! -f $SRC ]]; then
  tmp_src=$(mktemp "${TMPDIR:-/tmp}/kurenai.XXXXXX") || die 'no se pudo crear un archivo temporal'
  if command -v curl >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -fsSL --retry 3 -o "$tmp_src" -- "$REPO_RAW" \
      || die "no se pudo descargar $REPO_RAW"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$tmp_src" -- "$REPO_RAW" || die "no se pudo descargar $REPO_RAW"
  else
    die 'se necesita curl o wget para descargar kurenai'
  fi
  SRC=$tmp_src
fi
[[ -s $SRC ]] || die 'no se pudo obtener kurenai'
bash -n "$SRC" || die 'kurenai descargado no es un script válido'

if [[ -L $BASHRC ]]; then
  BASHRC=$(readlink -f -- "$BASHRC") || die "no se pudo resolver $BASHRC"
fi
if [[ -e $BASHRC && ! -f $BASHRC ]]; then
  die "$BASHRC no es un archivo regular"
fi

install -d -m 755 -- "$PREFIX" || die "no se pudo crear $PREFIX"
install -m 755 -- "$SRC" "$BIN" || die "no se pudo instalar $BIN"

block_exists=0
if [[ -f $BASHRC ]] && grep -qF -- "$MARK_BEGIN" "$BASHRC" 2>/dev/null; then
  block_exists=1
fi
if [[ -f $BASHRC ]] && { (( block_exists )) && ! grep -qF -- "$MARK_END" "$BASHRC" 2>/dev/null; }; then
  die "el bloque kurenai de $BASHRC está mal formado; edítalo a mano"
fi
if [[ -f $BASHRC ]] && ! (( block_exists )) && grep -qF -- "$MARK_END" "$BASHRC" 2>/dev/null; then
  die "el bloque kurenai de $BASHRC está mal formado; edítalo a mano"
fi
if (( block_exists )); then
  begin_line=$(grep -nF -m1 -- "$MARK_BEGIN" "$BASHRC" | cut -d: -f1)
  end_line=$(grep -nF -m1 -- "$MARK_END" "$BASHRC" | cut -d: -f1)
  if [[ -z $begin_line || -z $end_line || $begin_line -ge $end_line ]]; then
    die "el bloque kurenai de $BASHRC está mal formado; edítalo a mano"
  fi
fi

if (( AUTOSTART )) || { [[ -f $BASHRC ]] && (( block_exists )); }; then
  if [[ -e $BASHRC ]]; then
    cp -p -- "$BASHRC" "$BASHRC.kurenai.bak" || die "no se pudo hacer copia de $BASHRC"
  fi
  tmp_bashrc=$(mktemp "${BASHRC}.kurenai.XXXXXX") || die "no se pudo crear un temporal para $BASHRC"
  if [[ -e $BASHRC ]]; then
    awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "$BASHRC" > "$tmp_bashrc"
  fi
  if (( AUTOSTART )); then
    if [[ -s $tmp_bashrc ]] && [[ $(tail -c 1 -- "$tmp_bashrc" | wc -l) -eq 0 ]]; then
      printf '\n' >> "$tmp_bashrc"
    fi
    {
      printf '%s\n' "$MARK_BEGIN"
      printf 'if [[ %s == *i* && -z %s%s && -x %q ]]; then\n' '$-' '$' '{KURENAI_SHOWN:-}' "$BIN"
      printf '  KURENAI_SHOWN=1\n'
      printf '  export KURENAI_SHOWN\n'
      printf '  %q || true\n' "$BIN"
      printf 'fi\n'
      printf '%s\n' "$MARK_END"
    } >> "$tmp_bashrc"
  fi
  if [[ -e $BASHRC ]]; then
    chmod --reference="$BASHRC" "$tmp_bashrc" 2>/dev/null || true
  else
    chmod 644 "$tmp_bashrc" 2>/dev/null || true
  fi
  mv -f -- "$tmp_bashrc" "$BASHRC" || die "no se pudo actualizar $BASHRC"
  tmp_bashrc=''
fi

if (( AUTOSTART )); then
  printf 'kurenai: bloque de autoarranque actualizado en %s\n' "$BASHRC"
elif (( block_exists )); then
  printf 'kurenai: bloque de autoarranque eliminado de %s\n' "$BASHRC"
else
  printf 'kurenai: no hay bloque de autoarranque en %s\n' "$BASHRC"
fi

printf 'kurenai instalado en %s\n' "$BIN"
case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *) printf 'kurenai: advertencia: %s no está en PATH; usa %s o añádelo a PATH.\n' "$PREFIX" "$BIN" >&2 ;;
esac
if (( AUTOSTART )); then
  printf 'Abre una terminal nueva o ejecuta: source %s\n' "$BASHRC"
fi
