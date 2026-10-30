#!/usr/bin/env bash
set -euo pipefail

REPO_URL=${REPO_URL:-https://swbasmx.github.io/info-wc}
SUITE=${SUITE:-stable}
SOURCES_FILE=${SOURCES_FILE:-/etc/apt/sources.list.d/info-wc.list}

die() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}

[[ ${EUID:-$(id -u)} -eq 0 ]] || die 'ejecuta con sudo: sudo ./install.sh'
[[ -r /etc/os-release ]] || die 'no se encontró /etc/os-release'

. /etc/os-release

case "${ID:-} ${ID_LIKE:-}" in
  *debian*|*ubuntu*) ;;
  *) die "solo se soportan Debian/Ubuntu (detectado: ${PRETTY_NAME:-desconocido})" ;;
esac

command -v apt-get >/dev/null 2>&1 || die 'apt-get no está disponible'

printf 'Distro detectada: %s\n' "${PRETTY_NAME:-${ID:-desconocida}}"

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

apt-get update
apt-get install -y --no-install-recommends ca-certificates

printf 'deb [trusted=yes] %s %s main\n' "$REPO_URL" "$SUITE" > "$SOURCES_FILE"
chmod 644 -- "$SOURCES_FILE"

apt-get update
apt-get install -y info-wc

printf '\ninfo-wc instalado desde %s\n' "$REPO_URL"
printf 'Se mostrará al iniciar una shell de login.\n'
printf 'Para verlo ahora: info-wc\n'
