#!/usr/bin/env bash
set -euo pipefail

SOURCES_FILE=${SOURCES_FILE:-/etc/apt/sources.list.d/info-wc.list}

die() {
  printf 'uninstall.sh: %s\n' "$*" >&2
  exit 1
}

[[ ${EUID:-$(id -u)} -eq 0 ]] || die 'ejecuta con sudo: sudo ./uninstall.sh'
command -v apt-get >/dev/null 2>&1 || die 'apt-get no está disponible'

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

if dpkg -s info-wc >/dev/null 2>&1; then
  apt-get purge -y info-wc
else
  printf 'info-wc: no está instalado\n'
fi

rm -f -- "$SOURCES_FILE"
apt-get update || true

printf 'info-wc desinstalado y repositorio eliminado.\n'
