<p align="center">
  <img src="assets/banner-kurenai.svg" alt="kurenai: system info para terminal" width="100%">
</p>

<p align="center">
  <a href="#instalación"><img src="https://img.shields.io/badge/bash-4%2B-4EAA25?logo=gnubash&logoColor=white" alt="Bash 4+"></a>
  <a href="#compatibilidad"><img src="https://img.shields.io/badge/platform-Linux-FF0000?logo=linux&logoColor=white" alt="Linux"></a>
  <a href="#licencia"><img src="https://img.shields.io/badge/license-MIT-FF0000" alt="MIT"></a>
  <a href="#uso"><img src="https://img.shields.io/badge/version-3.2-FF0000" alt="Versión 3.2"></a>
  <a href="https://github.com/swbasmx/kurenai/actions/workflows/ci.yml"><img src="https://github.com/swbasmx/kurenai/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
</p>

<p align="center">
  <strong>System info para terminal. Rojo neón, dos columnas, modo monitor y cero dependencias raras.</strong>
</p>

<p align="center">
  <a href="#instalación">Instalación</a> ·
  <a href="#uso">Uso</a> ·
  <a href="#modo-monitor">Monitor</a> ·
  <a href="#cómo-funciona">Cómo funciona</a> ·
  <a href="#rendimiento">Rendimiento</a> ·
  <a href="#desarrollo">Desarrollo</a>
</p>

---

`kurenai` es un panel de sistema para terminal escrito en Bash. Muestra sistema, hardware, rendimiento y memoria en una interfaz roja, con barras, una sparkline de CPU y un layout que se adapta al ancho de la terminal. Puede ejecutarse una sola vez o quedarse en modo monitor.

Repositorio: <https://github.com/swbasmx/kurenai>

## Contenido

- [¿Qué es?](#qué-es)
- [Características](#características)
- [Vista rápida](#vista-rápida)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Uso](#uso)
- [Modo monitor](#modo-monitor)
- [Desinstalación](#desinstalación)
- [Cómo funciona](#cómo-funciona)
- [Rendimiento](#rendimiento)
- [Privacidad](#privacidad)
- [Configuración](#configuración)
- [Compatibilidad](#compatibilidad)
- [Desarrollo](#desarrollo)
- [Solución de problemas](#solución-de-problemas)
- [Hoja de ruta](#hoja-de-ruta)
- [Contribuir](#contribuir)
- [Licencia](#licencia)
- [Créditos](#créditos)

## ¿Qué es?

`kurenai` recoge datos de `/proc`, `/sys`, `df`, `lspci`, `nvidia-smi` y, si se permite, de un servicio de IP pública. Con esos datos dibuja un panel compacto en la terminal, sin imágenes ni dependencias de terceros.

El nombre viene de **紅** (*kurenai*), carmesí o rojo profundo en japonés.

Hay dos formas de usarlo:

- **One-shot**: ejecuta `kurenai` y muestra el panel una vez. Es el modo que usa el autoarranque.
- **Monitor**: ejecuta `kurenai -m` y el panel se refresca cada segundo. Está pensado para quedarse abierto en una terminal o en un panel lateral.

## Características

- **Rojo neón**: `#FF0000` en truecolor, con fallback a 256 y 16 colores.
- **Acento configurable**: `KURENAI_ACCENT="R G B"` cambia el color sin editar el script.
- **Dos columnas adaptativas**: a partir de 78 columnas; una sola columna en terminales angostas.
- **Barras** para CPU, temperatura, carga, GPU, RAM, swap, disco y batería.
- **Modo monitor en vivo** con `-m`: intervalo ajustable, pausa, refresco manual y salida limpia con `q`.
- **Carga legible**: la barra compara la carga con los núcleos y el detalle muestra `carga/núcleos`.
- **Sparkline de CPU** con las últimas 8 muestras.
- **Duración de animación ajustable** con `-t SEGUNDOS`; acepta coma decimal.
- **Idioma automático**: detecta `LANG`/`LC_ALL` y permite forzar `es` o `en` con `-l`.
- **Datos útiles**: kernel, shell, uptime, CPU, GPU, LAN, IP pública, temperatura y batería.
- **Caché de IP pública** con TTL de 15 minutos; los fallos se recuerdan 60 segundos y `-r` fuerza la actualización.
- **Consultas en paralelo**: la IP pública y la GPU se resuelven en segundo plano mientras se recogen el resto de datos.
- **Autoarranque opcional** al abrir una terminal, con guard para no repetirlo en subshells.
- **Instalador idempotente y actualizable**: reescribe el bloque marcado en `~/.bashrc`, no lo duplica y guarda una copia de seguridad.
- **Respeta tu terminal**: `NO_COLOR`, `TERM=dumb`, redirecciones, `-q` y variables de entorno para desactivar red o animación.

## Vista rápida

<p align="center">
  <img src="assets/preview.png" alt="kurenai en una terminal de 80 columnas" width="100%">
</p>

> Captura del panel de una sola vez a 80 columnas.

## Requisitos

- Linux.
- Bash 4+.
- Utilidades estándar: `awk`, `sed`, `df`, `ip` o `hostname`, y acceso a `/proc` y `/sys`.
- Opcionales:
  - `curl` para consultar la IP pública.
  - `lspci` para el modelo de GPU.
  - `nvidia-smi` o `gpu_busy_percent` para el uso de GPU.
  - `/sys/class/power_supply` para la batería.
  - `/sys/class/hwmon` o thermal zones para la temperatura.

## Instalación

```bash
curl -fsSLO https://raw.githubusercontent.com/swbasmx/kurenai/main/install.sh
sudo bash install.sh
```

El instalador descarga `kurenai`, lo copia a `~/.local/bin/kurenai`, guarda una copia de `~/.bashrc` en `~/.bashrc.kurenai.bak` y actualiza el bloque marcado de autoarranque. Si el bloque ya existe, lo reescribe para que apunte al prefijo correcto; no lo duplica.

Si lo ejecutas con `sudo`, instala para el usuario que lo invocó, no para `root`.

| Opción | Descripción |
| --- | --- |
| `--prefix DIR` | Directorio de instalación. Por defecto, `~/.local/bin`. |
| `--bashrc FILE` | Archivo de configuración. Por defecto, `~/.bashrc`. |
| `--no-autostart` | Instala el comando pero elimina el autoarranque. |
| `--repo URL` | URL alternativa para descargar `kurenai`. |

`PREFIX`, `BASHRC` y `REPO_RAW` también se pueden pasar como variables de entorno. Si usas `sudo` con `env_reset`, pasa las rutas como argumentos (`sudo bash install.sh --prefix ...`), porque sudo puede descartar esas variables.

Abre una terminal nueva o recarga tu configuración:

```bash
source ~/.bashrc
```

### Desde el repo

```bash
git clone https://github.com/swbasmx/kurenai.git
cd kurenai
./install.sh
```

### Sin autoarranque

Si solo quieres el comando disponible:

```bash
./install.sh --no-autostart
```

O instala el archivo a mano:

```bash
install -m 755 kurenai ~/.local/bin/kurenai
```

Asegúrate de que `~/.local/bin` esté en tu `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

También puedes ejecutarlo directamente desde el repo:

```bash
./kurenai
```

## Uso

```bash
kurenai            # panel animado
kurenai -t 1.5     # animación de 1.5 segundos
kurenai -l en      # salida en inglés
kurenai -q         # sin animación
kurenai -n         # sin consultar la IP pública
kurenai -r         # refresca la IP pública
kurenai -m         # modo monitor en vivo (1 s)
kurenai -m -i 0.5  # monitor cada 0.5 s
kurenai -V         # versión
kurenai -h         # ayuda
```

| Opción | Descripción |
| --- | --- |
| `-r`, `--refresh` | Ignora la caché y vuelve a consultar la IP pública. |
| `-n`, `--no-net` | No consulta la IP pública. |
| `-q`, `--no-anim` | Desactiva la animación y deja una salida estática. |
| `-t`, `--time S` | Duración de la animación en segundos (por defecto `0.3`). Acepta coma decimal. `0` la desactiva. |
| `-m`, `--monitor` | Modo monitor en vivo. Requiere una terminal interactiva. |
| `-i`, `--interval S` | Intervalo de refresco del monitor, 0.25–10 s. Implica `-m`. |
| `--frames N` | Renderiza N frames y sale. Útil para pruebas. |
| `-l`, `--lang L` | Idioma: `es` o `en` (también `es_ES`, `en_US`, etc.). Por defecto se detecta desde `LANG`/`LC_ALL`. |
| `-V`, `--version` | Muestra la versión. |
| `-h`, `--help` | Muestra la ayuda. |

### Variables de entorno

| Variable | Efecto |
| --- | --- |
| `KURENAI_LANG=es\|en` | Fuerza el idioma. |
| `KURENAI_NO_NET=1` | No consulta la IP pública. Equivale a `-n`. |
| `KURENAI_NO_ANIM=1` | Desactiva la animación. Equivale a `-q`. |
| `KURENAI_ACCENT="R G B"` | Color principal, por ejemplo `"0 255 180"`. Por defecto `"255 0 0"`. |
| `KURENAI_BAR_W=4..14` | Ancho de las barras. Por defecto `10`. |
| `KURENAI_WIDTH=40..84` | Fuerza el ancho del panel; útil para capturas o pruebas. |
| `KURENAI_INTERVAL=1` | Intervalo por defecto del modo monitor, en segundos. |

```bash
KURENAI_ACCENT="0 255 180" kurenai
KURENAI_NO_NET=1 kurenai -q
```

Si quieres que el autoarranque las use, define estas variables **antes** del bloque `# >>> kurenai >>>` de `~/.bashrc`.

## Modo monitor

```bash
kurenai -m
kurenai -m -i 0.5
kurenai -m -n          # oculta la IP pública
```

El modo monitor entra en la pantalla alternativa, oculta el cursor y redibuja el panel cada segundo. Mantiene la misma estética: rojo neón, barras `▰/▱`, reglas `─` y dos columnas.

<p align="center">
  <img src="assets/monitor.gif" alt="kurenai -m actualizando el panel en vivo" width="100%">
</p>

> GIF a 0.5 s para que se aprecie el refresco; el intervalo por defecto es 1 s.

| Tecla | Acción |
| --- | --- |
| `q` | Salir y restaurar la terminal. |
| `p` | Pausar/reanudar la recogida de datos. |
| `+` / `-` | Subir/bajar el intervalo (0.25–10 s). |
| `r` | Refrescar datos estáticos y la IP pública. |
| `h` | Mostrar/ocultar el pie de ayuda. |
| `Ctrl-C` | Salir restaurando la terminal. |

Notas:

- El autoarranque sigue siendo el panel de una sola vez; el monitor es opt-in con `-m`.
- La IP pública se consulta una vez por sesión (o al pulsar `r`); `-n` la oculta.
- El disco se refresca cada 5 s; el resto de métricas, cada tick.
- Si la terminal no llega al tamaño mínimo, muestra un aviso y espera a que la redimensiones o pulses `q`.
- En NVIDIA, el uso de GPU se actualiza en segundo plano cada pocos segundos para no bloquear la interfaz.

## Desinstalación

```bash
curl -fsSLO https://raw.githubusercontent.com/swbasmx/kurenai/main/uninstall.sh
sudo bash uninstall.sh
```

También puedes ejecutarlo desde el repo:

```bash
cd kurenai
./uninstall.sh
```

Elimina `~/.local/bin/kurenai`, el bloque marcado de `~/.bashrc` y la caché de la IP pública. No toca el resto del archivo. Si instalaste con `--prefix` o `--bashrc`, usa los mismos valores al desinstalar. Con `--keep-cache` conserva `${XDG_CACHE_HOME:-$HOME/.cache}/kurenai`.

```bash
./uninstall.sh --prefix ~/.local/bin --bashrc ~/.bashrc
./uninstall.sh --keep-cache
```

## Cómo funciona

### Fuentes de datos

```text
/proc/stat, /proc/meminfo, /proc/loadavg, /proc/uptime
/sys/class/thermal, /sys/class/hwmon, /sys/class/power_supply
/sys/class/drm, df, lspci, nvidia-smi
curl (solo IP pública, opcional)
                    │
                    ▼
        collect_static / collect_dynamic_tick
                    │
                    ▼
        render_panel / render_metrics / render_footer
                    │
                    ▼
                terminal
```

### One-shot

1. Se recogen los datos estáticos: kernel, shell, CPU, núcleos, frecuencia máxima, GPU y LAN.
2. La IP pública y el uso de GPU se resuelven en segundo plano.
3. Se recogen las métricas dinámicas: uptime, carga, RAM, swap, disco, temperatura, batería y CPU.
4. Se calculan los detalles de cada fila.
5. Se dibuja el panel y, si hay TTY, se animan la regla y las barras.

### Monitor

El bucle del monitor es intencionadamente ligero:

```text
leer tecla (timeout = intervalo)
  ↓
recoger métricas dinámicas
  ↓
dibujar el frame completo en una sola escritura
  ↓
repetir
```

- Los datos estáticos se recogen una vez al entrar y con `r`.
- La CPU se calcula con el delta de `/proc/stat` entre ticks; no hay `sleep` extra.
- La sparkline guarda las últimas 8 muestras.
- El disco se refresca cada 5 ticks.
- La IP pública se consulta una vez por sesión, salvo `r`.
- La GPU NVIDIA se actualiza con un poller en segundo plano; AMD/Intel se leen de sysfs.
- El frame se construye, se limpia la pantalla y se escribe de golpe para evitar parpadeo.
- Al salir se restauran el cursor, el modo del terminal y la pantalla anterior.

### Render y layout

- **Ancho**: si hay TTY usa `tput cols`; si no, `COLUMNS`; `KURENAI_WIDTH` lo fuerza. Se limita a 84 y usa 40 como mínimo.
- **Dos columnas** a partir de 78 columnas; una sola columna en terminales angostas.
- **Centrado**: en modo monitor, si la terminal es más ancha que el panel, se centra.
- **Cabeceras**: líneas `─` con la etiqueta centrada y en negrita.
- **Barras**: `▰` para lo lleno y `▱` para lo vacío.
- **Sparkline**: `▁▂▃▄▅▆▇█`.
- **Color**: truecolor, fallback a 256 y a 16 colores. Se desactiva si no hay TTY, si `NO_COLOR` está definido o si `TERM=dumb`.

### Caché

La IP pública se guarda en `${XDG_CACHE_HOME:-$HOME/.cache}/kurenai/public-ip` durante 15 minutos. Los fallos se recuerdan 60 segundos para no bloquear el arranque sin red. El archivo se crea con permisos `600`.

### Idioma

Se detecta `LC_ALL`, `LC_MESSAGES`, `LANGUAGE` o `LANG`. `-l es|en` lo fuerza y `KURENAI_LANG` hace lo mismo desde el entorno.

### Estructura del proyecto

| Archivo | Función |
| --- | --- |
| `kurenai` | Script principal, single-file. |
| `install.sh` | Instalador y autoarranque. |
| `uninstall.sh` | Desinstalador. |
| `tests/smoke.sh` | Pruebas de humo, PTY y ciclo de instalación. |
| `Makefile` | `make test`, `make lint`, `make check`. |
| `.github/workflows/ci.yml` | Lint y tests en CI. |
| `assets/banner-kurenai.svg` | Banner del README. |
| `assets/preview.png` | Captura del panel. |
| `assets/monitor.gif` | Demo del modo monitor. |

## Rendimiento

Medido en un equipo modesto, con `-n -q` para aislar la recogida de datos:

- Panel de una sola vez: alrededor de **0.6 s**.
- Monitor a 1 s: alrededor de **6% de un núcleo** y **7 MB de RSS**.
- El disco se refresca cada 5 s; el resto de métricas, cada tick.
- Los tiempos absolutos varían con la carga del sistema.

Para reducir el consumo:

```bash
kurenai -m -i 2     # refresco cada 2 s
kurenai -m -n       # sin consultar la IP
# pulsa p para pausar
```

## Privacidad

La IP pública se consulta a `api.ipify.org` (con `ifconfig.me/ip` como reserva) y se guarda en la caché local en texto plano. El archivo se crea con permisos `600`.

Para no consultarla nunca:

```bash
kurenai -n
kurenai -m -n
```

o define `KURENAI_NO_NET=1`. No hay telemetría, ni cuentas, ni envío de datos más allá de esa consulta.

El instalador guarda una copia de `~/.bashrc` antes de modificarlo, valida el script descargado con `bash -n` y descarga por HTTPS.

## Configuración

Casi todo vive al principio del script:

| Constante / variable | Qué controla |
| --- | --- |
| `BAR_W` / `KURENAI_BAR_W` | Ancho de las barras, 4..14. Por defecto, 10. |
| `TTL` | Duración de la caché de IP en segundos. Por defecto, 900. |
| `TTL_NEG` | Duración de la caché de fallos de IP. Por defecto, 60. |
| `LEFT_W` | Ancho de la columna izquierda. Por defecto, 34. |
| `GAP` | Separación entre columnas. Por defecto, 3. |
| `KURENAI_ACCENT` | Color principal en formato `"R G B"`. Por defecto, `"255 0 0"`. |
| `KURENAI_INTERVAL` | Intervalo por defecto del monitor, en segundos. |

Para cambiar el color sin editar el script:

```bash
KURENAI_ACCENT="0 255 180" kurenai
```

También puedes fijarlo en `~/.bashrc`:

```bash
export KURENAI_ACCENT="0 255 180"
```

Colócalo antes del bloque `# >>> kurenai >>>` para que también afecte al autoarranque.

## Compatibilidad

- Linux. El script depende de `/proc` y `/sys`.
- Bash 4+.
- Terminal con UTF-8 y soporte ANSI; funciona en terminales modernas, tmux y SSH.
- Truecolor, 256 colores y 16 colores.
- Opcionales: `curl`, `lspci`, `nvidia-smi`, batería y sensores.
- Probado en Linux con Bash 5.1; el código evita características que no existan en Bash 4.

## Desarrollo

```bash
git clone https://github.com/swbasmx/kurenai.git
cd kurenai
./kurenai -n -q
bash tests/smoke.sh
make check   # bash -n + shellcheck + smoke tests
```

Los tests cubren anchos de 40 a 120 columnas, ambos idiomas, la alineación de la regla superior, las variables de entorno, el modo monitor bajo PTY, la terminal pequeña y el ciclo instalar/desinstalar en un `HOME` temporal.

El workflow de GitHub Actions ejecuta lint y tests en cada push y pull request.

### Añadir una métrica

1. Recoge el dato en `collect_dynamic_tick` (o en `collect_static` si no cambia).
2. Añade la etiqueta a `t()` y a `init_labels`.
3. Añade la fila en `render_metrics` o en el cuerpo de `render_panel`.
4. Comprueba que el ancho sigue cuadrando en 40, 78, 80 y 84 columnas.
5. Ejecuta `make check`.

## Solución de problemas

- **La regla o las columnas se ven cortadas**: usa una terminal de al menos 40 columnas; el panel se limita a 84. `KURENAI_WIDTH=80` fuerza un ancho concreto.
- **No aparece la GPU**: instala `pciutils` (`lspci`). El uso de GPU necesita `nvidia-smi` o `gpu_busy_percent`.
- **No aparece la temperatura**: revisa que `/sys/class/hwmon` o `/sys/class/thermal` existan.
- **La IP tarda o sale offline**: usa `-n` o `KURENAI_NO_NET=1`; la consulta tiene un timeout de 1 s y la caché de fallos dura 60 s.
- **`kurenai: command not found`**: añade `~/.local/bin` al `PATH` (`export PATH="$HOME/.local/bin:$PATH"`).
- **El autoarranque no se ejecuta**: comprueba que `~/.bashrc` sea el archivo que usa tu shell y que el bloque exista una sola vez.
- **Quiero deshacer el autoarranque**: `./install.sh --no-autostart` o `./uninstall.sh`.
- **El modo monitor no arranca**: necesita stdin y stdout interactivos; ejecútalo directamente en una terminal, no con la salida redirigida.
- **Quiero reducir el consumo del monitor**: usa `-m -i 2` para refrescar cada 2 s, o `p` para pausarlo.
- **Se ve raro en una terminal sin UTF-8**: el panel usa `─`, `▰`, `▱` y `█`; usa una locale UTF-8.

### Preguntas frecuentes

**¿Necesita root?** No. El instalador usa `sudo` solo para lanzarse como tu usuario y escribir en tu `HOME`.

**¿Funciona en macOS?** No. Depende de `/proc` y `/sys` de Linux.

**¿Es un clon de neofetch?** Está inspirado en la idea de mostrar información del sistema en la terminal, pero es una implementación independiente en Bash.

**¿Por qué Bash?** Para que sea un único archivo, fácil de instalar y de leer, sin runtime adicional.

**¿Puedo usarlo en scripts?** Sí: `-q` deja una salida estática y `-n` evita la consulta de red. Respeta `NO_COLOR`, `TERM=dumb` y las redirecciones.

## Hoja de ruta

Ideas para próximas versiones, sin compromiso:

- Barras por núcleo.
- Gráficas de CPU/RAM más grandes.
- Red RX/TX con historial.
- Lista de procesos principales.
- Más temas de color.

## Contribuir

- Abre un issue antes de cambios grandes.
- Mantén el script en un solo archivo y sin dependencias nuevas.
- Ejecuta `make check` antes de enviar un PR.
- Respeta el estilo existente: Bash 4+, `shellcheck` limpio y tests en verde.
- Documenta cualquier opción o variable nueva en este README.

## Licencia

MIT. Consulta [LICENSE](LICENSE).

## Créditos

Inspirado por la idea de [neofetch](https://github.com/dylanaraps/neofetch) y por la densidad visual de herramientas como `btop` y `fastfetch`. `kurenai` es una implementación independiente, en Bash y sin relación con esos proyectos.
