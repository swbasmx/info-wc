#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT"

./build-deb.sh

VERSION=$(sed -n 's/^VERSION=//p' info-wc | head -n1)
PKG=info-wc
DOCS=$ROOT/docs
POOL=$DOCS/pool/main/i/$PKG
DIST=$DOCS/dists/stable
BIN=$DIST/main/binary-all
DEB=$ROOT/dist/${PKG}_${VERSION}_all.deb

rm -rf -- "$DOCS"
mkdir -p -- "$POOL" "$BIN"
cp -- "$DEB" "$POOL/"
: > "$DOCS/.nojekyll"

cat > "$DOCS/index.html" <<'EOF'
<!doctype html>
<html lang="es">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>info-wc — repositorio APT</title>
<style>
  :root { color-scheme: dark; }
  body {
    margin: 0;
    min-height: 100vh;
    display: grid;
    place-items: center;
    background: radial-gradient(circle at 20% 0%, #3a0000, #08080b 55%);
    color: #eee;
    font: 16px/1.6 system-ui, sans-serif;
  }
  main { width: min(760px, 92vw); }
  h1 { color: #ff0000; font: 700 3rem/1 monospace; margin: 0 0 .5rem; }
  p { color: #bbb; }
  pre {
    overflow-x: auto;
    padding: 1rem;
    border: 1px solid #3a1015;
    border-radius: 10px;
    background: #0d0d11;
    color: #ff4b4b;
  }
  a { color: #ff4b4b; }
</style>
<main>
  <h1>info-wc</h1>
  <p>Repositorio APT del panel de sistema en rojo neón.</p>
  <pre>echo "deb [trusted=yes] https://swbasmx.github.io/info-wc stable main" \
  | sudo tee /etc/apt/sources.list.d/info-wc.list
sudo apt update
sudo apt install info-wc</pre>
  <p>Instalador y código: <a href="https://github.com/swbasmx/info-wc">github.com/swbasmx/info-wc</a>.</p>
</main>
</html>
EOF

(
  cd "$DOCS"
  apt-ftparchive packages pool > dists/stable/main/binary-all/Packages
)

gzip -9 -kf -- "$BIN/Packages"

release_tmp=$(mktemp)
cleanup() {
  if [[ -n ${release_tmp:-} ]]; then
    rm -f -- "$release_tmp"
  fi
  return 0
}
trap cleanup EXIT

(
  cd "$DIST"
  apt-ftparchive \
    -o APT::FTPArchive::Release::Origin="$PKG" \
    -o APT::FTPArchive::Release::Label="$PKG" \
    -o APT::FTPArchive::Release::Suite=stable \
    -o APT::FTPArchive::Release::Codename=stable \
    -o APT::FTPArchive::Release::Architectures=all \
    -o APT::FTPArchive::Release::Components=main \
    release . > "$release_tmp"
)

mv -- "$release_tmp" "$DIST/Release"
chmod 644 -- "$DIST/Release"
release_tmp=''

printf 'Repositorio APT generado en %s\n' "$DOCS"
