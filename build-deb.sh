#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT"

VERSION=$(sed -n 's/^VERSION=//p' info-wc | head -n1)
[[ $VERSION =~ ^[0-9][0-9A-Za-z.+:~-]*$ ]] || {
  printf 'build-deb.sh: versión inválida: %s\n' "${VERSION:-<vacía>}" >&2
  exit 1
}

PKG=info-wc
ARCH=all
BUILD=$ROOT/build
DEBROOT=$BUILD/${PKG}_${VERSION}_${ARCH}
DIST=$ROOT/dist
DEB=$DIST/${PKG}_${VERSION}_${ARCH}.deb

rm -rf -- "$BUILD" "$DIST"
mkdir -p -- \
  "$DEBROOT/DEBIAN" \
  "$DEBROOT/usr/bin" \
  "$DEBROOT/usr/share/doc/$PKG" \
  "$DEBROOT/etc/profile.d" \
  "$DIST"

install -Dm755 -- info-wc "$DEBROOT/usr/bin/info-wc"
install -Dm644 -- packaging/profile.d/info-wc.sh "$DEBROOT/etc/profile.d/info-wc.sh"
install -Dm644 -- LICENSE "$DEBROOT/usr/share/doc/$PKG/copyright"

SIZE=$(du -sk "$DEBROOT/usr" "$DEBROOT/etc" | awk '{ total += $1 } END { print total }')

cat > "$DEBROOT/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Depends: bash (>= 4), coreutils, gawk | mawk, sed, iproute2, hostname, curl, pciutils, ncurses-bin
Maintainer: swbasmx <swbasmx@localhost>
Installed-Size: $SIZE
Homepage: https://github.com/swbasmx/info-wc
Description: Panel de sistema para terminal en rojo neón
 Muestra sistema, hardware, rendimiento y memoria en una
 interfaz roja con barras animadas y layout adaptativo.
EOF

printf '/etc/profile.d/info-wc.sh\n' > "$DEBROOT/DEBIAN/conffiles"

(
  cd "$DEBROOT"
  find usr etc -type f -print0 | sort -z | xargs -0 md5sum > DEBIAN/md5sums
)

chmod 644 -- \
  "$DEBROOT/DEBIAN/control" \
  "$DEBROOT/DEBIAN/conffiles" \
  "$DEBROOT/DEBIAN/md5sums"

dpkg-deb --build --root-owner-group "$DEBROOT" "$DEB"
printf 'Paquete creado: %s\n' "$DEB"
