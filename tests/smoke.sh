#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
BIN=$ROOT/kurenai
TMP=$(mktemp -d "${TMPDIR:-/tmp}/kurenai-test.XXXXXX")
trap 'rm -rf -- "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  printf 'ok - %s\n' "$*"
}

if locale -a 2>/dev/null | grep -qiE '^C\.utf-?8$'; then
  export LC_ALL=C.UTF-8
  utf8=1
elif locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
  export LC_ALL=en_US.UTF-8
  utf8=1
else
  export LC_ALL=C
  utf8=0
fi

bash -n "$BIN"
pass 'sintaxis'

for lang in es en; do
  for w in 40 78 80 84 120; do
    out=$TMP/out-$lang-$w
    COLUMNS=$w "$BIN" -n -q -l "$lang" > "$out" || fail "$lang/$w terminó con error"
    if (( utf8 )); then
      while IFS= read -r line; do
        if (( ${#line} > w )); then
          fail "$lang/$w línea de ${#line} columnas: $line"
        fi
      done < "$out"
    fi
    pass "$lang/$w"
  done
done

for w in 78 80 84; do
  out=$TMP/wide-$w
  COLUMNS=$w "$BIN" -n -q -l es > "$out"
  expected=$(( w - 2 ))
  rule=$(grep -m1 -E '^  ─+$' "$out" || true)
  [[ -n $rule ]] || fail "$w sin regla superior"
  (( ${#rule} == expected )) || fail "$w regla ${#rule} != $expected"
  pass "$w regla $expected"
done

if grep -qE '[0-9]{4,}%' "$TMP/out-es-80"; then
  fail 'porcentaje de cuatro dígitos'
fi
pass 'sin porcentajes desbordados'

if grep -qF -- 'sin swap' "$TMP/out-en-80"; then
  fail "inglés contiene 'sin swap'"
fi
if grep -qF -- 'desconocido' "$TMP/out-en-80"; then
  fail "inglés contiene 'desconocido'"
fi
pass 'i18n en'

KURENAI_WIDTH=60 KURENAI_BAR_W=14 KURENAI_ACCENT='0 255 180' \
  "$BIN" -n -q > "$TMP/env" || fail 'variables de entorno'
while IFS= read -r line; do
  if (( utf8 && ${#line} > 60 )); then
    fail "KURENAI_WIDTH línea de ${#line} columnas"
  fi
done < "$TMP/env"
cpu_line=$(grep '^  CPU ' "$TMP/env" | tail -n1)
cells=$(printf '%s\n' "$cpu_line" | grep -oE '▰|▱' | wc -l)
(( cells == 14 )) || fail "KURENAI_BAR_W celdas=$cells"
pass 'variables de entorno'

"$BIN" -V | grep -q '^kurenai 3\.' || fail 'versión'
"$BIN" -l es -h | grep -q 'uso: kurenai' || fail 'ayuda'
"$BIN" -n -q -t 0 >/dev/null || fail '-t 0'
"$BIN" -n -q -t 1,5 >/dev/null || fail '-t 1,5'
if "$BIN" -l fr >/dev/null 2>&1; then fail '-l fr debería fallar'; fi
if "$BIN" -t abc >/dev/null 2>&1; then fail '-t abc debería fallar'; fi
pass 'opciones'

if command -v script >/dev/null 2>&1; then
  if command -v timeout >/dev/null 2>&1; then TO=(timeout 15); else TO=(); fi
  "${TO[@]}" script -qec "$BIN -m -n -l es -i 0.1 --frames 3" /dev/null > "$TMP/monitor" 2>/dev/null || fail 'monitor --frames'
  grep -q $'\033\[?1049h' "$TMP/monitor" || fail 'monitor no entró en pantalla alternativa'
  grep -q $'\033\[?1049l' "$TMP/monitor" || fail 'monitor no salió de pantalla alternativa'
  grep -q $'\033\[?25l' "$TMP/monitor" || fail 'monitor no ocultó el cursor'
  grep -q $'\033\[?25h' "$TMP/monitor" || fail 'monitor no restauró el cursor'
  grep -q 'SISTEMA' "$TMP/monitor" || fail 'monitor sin panel'
  grep -q 'q salir' "$TMP/monitor" || fail 'monitor sin pie'
  frames=$(grep -ao 'SISTEMA' "$TMP/monitor" | wc -l)
  (( frames == 3 )) || fail "monitor frames=$frames"
  pass 'monitor'

  "${TO[@]}" script -qec "stty rows 10 cols 30; $BIN -m -n -l es -i 0.1 --frames 2" /dev/null > "$TMP/monitor-small" 2>/dev/null || fail 'monitor terminal pequeña'
  grep -q 'terminal demasiado pequeña' "$TMP/monitor-small" || fail 'monitor no avisó de terminal pequeña'
  pass 'monitor terminal pequeña'
else
  printf 'ok - monitor (omitido: falta script)\n'
fi
if "$BIN" -m -n >/dev/null 2>&1; then fail 'monitor sin TTY debería fallar'; fi
pass 'monitor sin TTY'

H=$TMP/home
mkdir -p "$H"
printf 'alias ll="ls -l"\n' > "$H/.bashrc"
HOME=$H bash "$ROOT/install.sh" --prefix "$H/bin" --bashrc "$H/.bashrc" >/dev/null
[[ -x $H/bin/kurenai ]] || fail 'el instalador no creó el binario'
count=$(grep -cF '# >>> kurenai >>>' "$H/.bashrc" || true)
(( count == 1 )) || fail "bloques tras instalar: $count"

HOME=$H bash "$ROOT/install.sh" --prefix "$H/bin2" --bashrc "$H/.bashrc" >/dev/null
count=$(grep -cF '# >>> kurenai >>>' "$H/.bashrc" || true)
(( count == 1 )) || fail "bloques tras reinstalar: $count"
grep -qF "$H/bin2/kurenai" "$H/.bashrc" || fail 'el bloque no apunta al nuevo prefijo'
[[ -f $H/.bashrc.kurenai.bak ]] || fail 'no se creó la copia de .bashrc'

HOME=$H bash "$ROOT/install.sh" --prefix "$H/bin2" --bashrc "$H/.bashrc" --no-autostart >/dev/null
if grep -qF '# >>> kurenai >>>' "$H/.bashrc"; then fail '--no-autostart no eliminó el bloque'; fi

mkdir -p "$H/.cache/kurenai"
: > "$H/.cache/kurenai/public-ip"
XDG_CACHE_HOME=$H/.cache HOME=$H bash "$ROOT/uninstall.sh" --prefix "$H/bin2" --bashrc "$H/.bashrc" >/dev/null
[[ ! -e $H/bin2/kurenai ]] || fail 'el desinstalador no eliminó el binario'
if grep -qF '# >>> kurenai >>>' "$H/.bashrc"; then fail 'el desinstalador no eliminó el bloque'; fi
[[ ! -d $H/.cache/kurenai ]] || fail 'el desinstalador no eliminó la caché'
grep -qF 'alias ll="ls -l"' "$H/.bashrc" || fail 'el desinstalador tocó el resto de .bashrc'
pass 'instalador'

printf 'todo ok\n'
