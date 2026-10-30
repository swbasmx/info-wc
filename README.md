<p align="center">
  <img src="assets/banner.png" alt="info-wc: system info en rojo neón" width="100%">
</p>

<p align="center">
  <a href="#requisitos"><img src="https://img.shields.io/badge/bash-4%2B-4EAA25?logo=gnubash&logoColor=white" alt="Bash 4+"></a>
  <a href="#requisitos"><img src="https://img.shields.io/badge/platform-Linux-FF0000?logo=linux&logoColor=white" alt="Linux"></a>
  <a href="#características"><img src="https://img.shields.io/badge/dependencias-ninguna-FF0000" alt="Sin dependencias"></a>
  <a href="#licencia"><img src="https://img.shields.io/badge/license-MIT-FF0000" alt="MIT"></a>
  <a href="#uso"><img src="https://img.shields.io/badge/version-3.0-FF0000" alt="Versión 3.0"></a>
</p>

<p align="center">
  <strong>System info para terminal. Rojo neón, dos columnas y cero dependencias raras.</strong>
</p>

---

`info-wc` es un panel de sistema para terminal escrito en Bash. Muestra sistema, hardware, rendimiento y memoria en una interfaz roja, con barras animadas y un layout que se adapta al ancho de la terminal.

## Características

- **Rojo neón real**: `#FF0000` en truecolor, con fallback a 256 y 16 colores.
- **Dos columnas adaptativas**: a partir de 78 columnas; una sola columna en terminales angostas.
- **Barras animadas** para CPU, temperatura, carga, GPU, RAM, swap, disco y batería.
- **Sparkline de CPU** con las últimas 8 muestras.
- **Datos útiles**: kernel, shell, uptime, CPU, GPU, LAN, IP pública, temperatura y batería.
- **Caché de IP pública** con TTL de 15 minutos; `-r` fuerza la actualización.
- **Instalación y desinstalación limpias**: scripts idempotentes que añaden y eliminan el bloque de `~/.bashrc`.
- **Sin dependencias pesadas**: nada de Python, Node ni temas externos.
- **Respeta tu terminal**: `NO_COLOR`, `TERM=dumb`, redirecciones y el flag `-q`.

## Capturas

<p align="center">
  <img src="assets/preview-wide.png" alt="info-wc en una terminal de 80 columnas" width="100%">
</p>

<details>
<summary><strong>Vista en 40 columnas</strong></summary>

<br>

<p align="center">
  <img src="assets/preview-narrow.png" alt="info-wc en una terminal de 40 columnas" width="420">
</p>

</details>

> Las IPs de las capturas son de ejemplo; no corresponden a la red del autor.

## Requisitos

- Linux. Probado con Bash 5.1.
- Bash 4+.
- Utilidades estándar: `awk`, `sed`, `df`, `ip` o `hostname`, y acceso a `/proc` y `/sys`.
- Opcionales:
  - `curl` para consultar la IP pública.
  - `lspci` para el modelo de GPU.
  - `nvidia-smi` o `gpu_busy_percent` para el uso de GPU.
  - `/sys/class/power_supply` para la batería.
  - `/sys/class/hwmon` o thermal zones para la temperatura.

## Instalación

### Automática (recomendada)

```bash
git clone <URL-del-repo> info-wc
cd info-wc
./install.sh
```

Sustituye `<URL-del-repo>` por la URL de tu repositorio.

El instalador:

- copia `info-wc` a `~/.local/bin/info-wc`;
- añade un bloque marcado a `~/.bashrc` para ejecutarlo al abrir una terminal interactiva;
- es idempotente: si el bloque ya existe, no lo duplica.

El bloque que añade es equivalente a:

```bash
# >>> info-wc >>>
if [[ $- == *i* && -x "$HOME/.local/bin/info-wc" ]]; then
  "$HOME/.local/bin/info-wc"
fi
# <<< info-wc <<<
```

Abre una terminal nueva o recarga tu configuración:

```bash
source ~/.bashrc
```

La instalación automática está pensada para usarlo como pantalla de bienvenida. Si solo quieres el comando disponible, usa la instalación manual.

### Manual

Si ya tienes el repo clonado y no quieres tocar tu `.bashrc`:

```bash
install -m 755 info-wc ~/.local/bin/info-wc
```

Asegúrate de que `~/.local/bin` esté en tu `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

También puedes ejecutarlo sin instalarlo:

```bash
chmod +x info-wc
./info-wc
```

## Uso

```bash
info-wc          # panel animado
info-wc -q       # sin animación
info-wc -n       # sin consultar la IP pública
info-wc -r       # refresca la IP pública
info-wc -V       # versión
info-wc -h       # ayuda
```

| Opción | Descripción |
| --- | --- |
| `-r`, `--refresh` | Ignora la caché y vuelve a consultar la IP pública. |
| `-n`, `--no-net` | No consulta la IP pública. |
| `-q`, `--no-anim` | Desactiva la animación y deja una salida estática. |
| `-V`, `--version` | Muestra la versión. |
| `-h`, `--help` | Muestra la ayuda. |

## Desinstalación

```bash
cd info-wc
./uninstall.sh
```

Elimina `~/.local/bin/info-wc` y el bloque marcado de `~/.bashrc`. No toca el resto del archivo. Si el bloque no existe, solo elimina el binario.

Si instalaste con `PREFIX` o `BASHRC` personalizados, usa los mismos valores al desinstalar. Si ya no tienes el repo, borra a mano el bloque entre `# >>> info-wc >>>` y `# <<< info-wc <<<` y elimina `~/.local/bin/info-wc`.

## Cómo funciona

- **Ancho**: lee `COLUMNS` o `tput cols`, lo limita a 84 y usa 40 como mínimo.
- **Layout**: con 78+ columnas usa dos columnas: 34 para la izquierda, 3 de separación y el resto para la derecha. Si no, apila todo en una columna.
- **Cabeceras**: líneas `─` con la etiqueta centrada y en negrita.
- **Barras**: `▰` para lo lleno y `▱` para lo vacío; 10 celdas por barra.
- **Animación**: dibuja la regla superior y rellena las barras en 6 pasos; usa `\033[5A` para redibujar sin parpadeo.
- **Color**: truecolor `255;0;0`, fallback a `196` en 256 colores y `91` en 16 colores. Se desactiva si no hay TTY, si `NO_COLOR` está definido o si `TERM=dumb`.
- **Caché**: la IP pública se guarda en `${XDG_CACHE_HOME:-$HOME/.cache}/info-wc/public-ip` durante 15 minutos.

## Personalización

Casi todo vive al principio del script:

| Constante | Qué controla |
| --- | --- |
| `BAR_W` | Ancho de las barras. Por defecto, 10. |
| `TTL` | Duración de la caché de IP en segundos. Por defecto, 900. |
| `LEFT_W` | Ancho de la columna izquierda. Por defecto, 34. |
| `GAP` | Separación entre columnas. Por defecto, 3. |
| `C_RED` | Color principal de toda la interfaz. |

Para cambiar el color, edita esta línea:

```bash
C_RED=$(fg 255 0 0)
```

Por ejemplo, para un verde azulado:

```bash
C_RED=$(fg 0 255 180)
```

El fallback de 16 colores está pensado para rojo; ajústalo si cambias el color principal.

## Estructura

```text
info-wc/
├── info-wc
├── install.sh
├── uninstall.sh
├── assets/
│   ├── banner.png
│   ├── preview-wide.png
│   └── preview-narrow.png
├── README.md
└── LICENSE
```

## Contribuir

Issues y PRs son bienvenidos. Si vas a tocar el layout, pruébalo al menos a 40 y 80 columnas.

## Licencia

MIT. Consulta [LICENSE](LICENSE).

## Créditos

Inspirado por [neofetch](https://github.com/dylanaraps/neofetch). `info-wc` es una implementación independiente, en Bash y sin relación con el proyecto original.
