<p align="center">
  <img src="assets/banner.png" alt="info-wc: system info en rojo neón" width="100%">
</p>

<p align="center">
  <a href="#instalación"><img src="https://img.shields.io/badge/bash-4%2B-4EAA25?logo=gnubash&logoColor=white" alt="Bash 4+"></a>
  <a href="#instalación"><img src="https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu-FF0000?logo=debian&logoColor=white" alt="Debian / Ubuntu"></a>
  <a href="#instalación"><img src="https://img.shields.io/badge/apt-repositorio-FF0000" alt="Repositorio APT"></a>
  <a href="#licencia"><img src="https://img.shields.io/badge/license-MIT-FF0000" alt="MIT"></a>
  <a href="#uso"><img src="https://img.shields.io/badge/version-3.0-FF0000" alt="Versión 3.0"></a>
</p>

<p align="center">
  <strong>System info para terminal. Rojo neón, dos columnas y cero dependencias raras.</strong>
</p>

---

`info-wc` es un panel de sistema para terminal escrito en Bash. Muestra sistema, hardware, rendimiento y memoria en una interfaz roja, con barras animadas y un layout que se adapta al ancho de la terminal.

- Código: <https://github.com/swbasmx/info-wc>
- Repositorio APT: <https://swbasmx.github.io/info-wc>

## Características

- **Rojo neón real**: `#FF0000` en truecolor, con fallback a 256 y 16 colores.
- **Dos columnas adaptativas**: a partir de 78 columnas; una sola columna en terminales angostas.
- **Barras animadas** para CPU, temperatura, carga, GPU, RAM, swap, disco y batería.
- **Sparkline de CPU** con las últimas 8 muestras.
- **Datos útiles**: kernel, shell, uptime, CPU, GPU, LAN, IP pública, temperatura y batería.
- **Caché de IP pública** con TTL de 15 minutos; `-r` fuerza la actualización.
- **Paquete APT**: instala y desinstala con `apt`, resolviendo las dependencias.
- **Autoarranque sin `~/.bashrc`**: usa `/etc/profile.d/info-wc.sh`, propiedad del paquete.
- **Instalador con detección de distro**: comprueba `/etc/os-release` antes de tocar APT.
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

## Instalación

### Automática

```bash
curl -fsSLO https://raw.githubusercontent.com/swbasmx/info-wc/main/install.sh
sudo bash install.sh
```

O desde el repositorio:

```bash
git clone https://github.com/swbasmx/info-wc.git
cd info-wc
sudo ./install.sh
```

El instalador:

- detecta Debian/Ubuntu leyendo `/etc/os-release`;
- añade el repositorio APT `https://swbasmx.github.io/info-wc`;
- instala `info-wc` y sus dependencias con `apt`;
- deja el autoarranque en `/etc/profile.d/info-wc.sh`, sin tocar `~/.bashrc`.

### Manual con APT

```bash
echo "deb [trusted=yes] https://swbasmx.github.io/info-wc stable main" \
  | sudo tee /etc/apt/sources.list.d/info-wc.list

sudo apt update
sudo apt install info-wc
```

> El repositorio no está firmado; por eso usa `[trusted=yes]`. Si prefieres no confiar en un repo sin firma, compila el `.deb` con `./build-deb.sh` e instálalo con `sudo apt install ./dist/info-wc_3.0_all.deb`.

### Autoarranque

El paquete instala `/etc/profile.d/info-wc.sh`, que ejecuta `info-wc` al abrir una **shell de login** interactiva. No modifica `~/.bashrc` ni archivos personales.

Si abres una pestaña que no es una shell de login, ejecuta `info-wc` manualmente. No hay un mecanismo estándar para cada pestaña sin tocar el rc del shell.

Para desactivarlo temporalmente:

```bash
INFO_WC_SKIP=1 bash -l
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
curl -fsSLO https://raw.githubusercontent.com/swbasmx/info-wc/main/uninstall.sh
sudo bash uninstall.sh
```

O a mano:

```bash
sudo apt purge info-wc
sudo rm -f /etc/apt/sources.list.d/info-wc.list
sudo apt update
```

No hay ningún bloque en `~/.bashrc` que limpiar.

## Requisitos

- Debian o Ubuntu con `apt`.
- El paquete declara e instala: `bash`, `coreutils`, `gawk | mawk`, `sed`, `iproute2`, `hostname`, `curl` y `pciutils`.
- Opcionales:
  - `nvidia-smi` o `gpu_busy_percent` para el uso de GPU.
  - `/sys/class/power_supply` para la batería.
  - `/sys/class/hwmon` o thermal zones para la temperatura.

## Cómo funciona

- **Ancho**: lee `COLUMNS` o `tput cols`, lo limita a 84 y usa 40 como mínimo.
- **Layout**: con 78+ columnas usa dos columnas: 34 para la izquierda, 3 de separación y el resto para la derecha. Si no, apila todo en una columna.
- **Cabeceras**: líneas `─` con la etiqueta centrada y en negrita.
- **Barras**: `▰` para lo lleno y `▱` para lo vacío; 10 celdas por barra.
- **Animación**: dibuja la regla superior y rellena las barras en 6 pasos; usa `\033[5A` para redibujar sin parpadeo.
- **Color**: truecolor `255;0;0`, fallback a `196` en 256 colores y `91` en 16 colores. Se desactiva si no hay TTY, si `NO_COLOR` está definido o si `TERM=dumb`.
- **Caché**: la IP pública se guarda en `${XDG_CACHE_HOME:-$HOME/.cache}/info-wc/public-ip` durante 15 minutos.

## Desarrollo

```bash
./build-deb.sh
sudo apt install ./dist/info-wc_3.0_all.deb

./build-repo.sh
```

`build-deb.sh` genera el `.deb` en `dist/`. `build-repo.sh` regenera `docs/`, que es el repositorio APT publicado con GitHub Pages.

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
├── build-deb.sh
├── build-repo.sh
├── packaging/
│   └── profile.d/
│       └── info-wc.sh
├── docs/
│   ├── dists/
│   ├── pool/
│   └── index.html
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
