# devlab

Estación de trabajo de desarrollo reproducible, desplegable con un solo comando.

Entorno para Data Engineering (Polars, DuckDB, PySpark para tests, AWS/GCP),
edición modal (Helix) y un multiplexor consciente de agentes (**herdr**), sobre
**Debian 13**.

Sin Nix. La gestión es:

- **apt** — paquetes del sistema (Debian).
- **rustup** — toolchain de Rust (Rust, rust-analyzer).
- **uv** — Python por proyecto (`uv.lock`, `.venv`), no a nivel de sistema.
- **go** — toolchain de Go (para binarios como lazysql).
- **chezmoi** — dotfiles y configuración con plantillas por perfil.
- **Cloudflare R2** — datos persistentes.

El entorno es idéntico mires desde donde mires: en el VPS, el **terminal por
defecto es herdr** (toda sesión interactiva entra o se adjunta a él), así que al
conectarte por SSH o desde el móvil obtienes la misma distribución, atajos,
editor y tema sin configurar cada dispositivo.

---

## Despliegue con un solo comando

Punto de entrada único para ambos roles (tu máquina cliente o un VPS remoto).
Desde cualquier dispositivo Linux (x86_64 o aarch64, incluido Android/Termux):

```bash
curl -fsSL https://raw.githubusercontent.com/bit-crew/devlab/main/install.sh | sh
```

`install.sh` descarga el binario precompilado `devlab-install` (publicado por
GitHub Actions en la release `latest`), verifica su checksum y lo ejecuta. Toda
la lógica de instalación vive en ese binario Rust.

Modos (también pasables como argumento):

- **`vps`** (desde el cliente) — pregunta IP y usuario del VPS, se conecta por
  SSH y ejecuta la instalación allá con perfil `vps`. No instala claves SSH.
- **`dc1`** — instala el perfil cliente en este mismo equipo.

No requiere clonar nada ni tener Python: solo `sh` (y `ssh` para el VPS).

El CI compila el binario para **x86_64-linux** y **aarch64-linux** (musl
estático, para ARM/Termux). macOS y Windows se añadirán cuando el CI los
produzca.

**Modelo de responsabilidades:** configurar el VPS deja el servidor con el
entorno y el agente instalados. Enlazar un cliente al VPS por clave SSH es tarea
del cliente: cada máquina (tablet, laptop) genera su clave y la registra en el
VPS.

---

## Perfiles

| Perfil | Descripción | Rol |
|--------|-------------|-----|
| `dc1`  | Máquina local (Data Center 1) | Edición offline, se conecta al VPS por SSH |
| `vps`  | Servidor (OVHcloud, Debian) | Trabajo de datos, agente always-on, acceso móvil |

Reparto de herramientas (resumen):

- **Ambos:** git, openssh, zsh, curl, jq, helix, **herdr**, lazygit, lazysql,
  yazi, ripgrep, fd, fzf, bat, zoxide, eza, atuin, starship, direnv, chezmoi,
  uv, Python (vía uv), rustup + rust-analyzer, go.
- **Solo VPS:** JDK (PySpark para tests), AWS CLI, Terraform, sops, age,
  GCP SDK, toolchain C/C++ + clangd, el agente (**Pi + gentle-ai**), y
  **moshi-hook** (puente para operar el agente desde el móvil).

Los paquetes del sistema se declaran en `packages/system.txt` (por perfil y
gestor: apt/pkg/brew); las toolchains y binarios los instala `devlab-install`
desde release/cargo/go.

---

## El terminal: herdr como entorno por defecto (VPS)

herdr es un multiplexor consciente de agentes (como tmux, pero orientado a
agentes de IA y a ratón/móvil). En el perfil VPS:

- El `.zshrc` hace `exec herdr` en toda sesión interactiva (SSH, consola, móvil),
  salvo que ya estés dentro de herdr. Así el entorno es idéntico desde cualquier
  cliente.
- Trae un **tema zenbones "dark warm"** (gris cálido + texto hueso + acentos
  tostados) definido en una **paleta central** (ver abajo).
- Atajos para abrir herramientas en popup (prefijo `Ctrl+b`, luego la tecla):
  `prefix+plus` → lazygit, `prefix+a` → helix, `prefix+d` → lazysql.
- Aliases: `hx` (helix), `lg` (lazygit), `db` (lazysql).

### Acceso móvil (Moshi)

En el VPS se instala **moshi-hook**, el puente que permite ver y operar el
agente (Pi) desde la app Moshi en el teléfono. Corre como servicio systemd de
usuario con `linger` (sobrevive reinicios sin sesión abierta) y usa SSH/Mosh. El
binario habilita el servidor SSH y el linger automáticamente en el perfil VPS.

---

## Tema del entorno: paleta central

Una sola fuente de color configura todo el ambiente. En
`home/.chezmoidata.yaml`, el bloque `palette:` define ~12 colores (zenbones dark
warm). Cada plantilla los consume vía `{{ .palette.<clave> }}`:

- herdr (`[theme.custom]`), Helix (tema `zenbones_warm`), lazygit (bordes/selección).

Cambiar un color en `.chezmoidata.yaml` reconfigura herdr, Helix y lazygit a la
vez. El tema aplica al perfil `vps`.

---

## El agente (solo VPS)

Al aplicar el perfil `vps`, el binario instala y configura el agente:

- **Pi + gentle-ai** como agente de trabajo.
- **Skills:** devlab NO copia skills; las gestiona el repo aparte
  **[`bit-crew/prim-skills`](https://github.com/bit-crew/prim-skills)**, que
  instala sus propias skills más externas (Archify, ponytail, ...) en
  `~/.agents/skills` (raíz que Pi escanea).
- devlab sí concatena **sus** instructions en el `AGENTS.md` de Pi (steering
  específico de devlab) y mantiene **Engram local** (sin Engram Cloud).

---

## Estructura del repositorio

```text
devlab/
├── install.sh                # punto de entrada: baja y ejecuta el binario
├── installer/                # binario Rust devlab-install (toda la logica)
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs           # orquestacion + chezmoi + dotfiles
│       ├── binaries.rs       # toolchains, binarios, infra VPS, moshi
│       └── gentle.rs         # curado del agente Pi (instructions + Engram)
├── docs/                     # compra del VPS, multi-cuenta, ...
├── packages/
│   ├── system.txt            # paquetes del sistema por perfil y gestor
│   └── cargo.txt             # componentes rustup + herramientas cargo
├── home/                     # source de chezmoi (dotfiles)
│   ├── .chezmoi.toml.tmpl
│   ├── .chezmoidata.yaml     # paleta central del tema
│   ├── dot_zshrc.tmpl        # exec herdr, aliases, COLORTERM
│   └── dot_config/           # herdr, helix (+themes), lazygit, atuin, ...
├── TODO.md
├── .github/workflows/        # CI: build del binario (x86_64 + aarch64) + validacion
└── README.md
```

---

## El binario devlab-install

`install.sh` lo descarga y ejecuta por ti, pero el binario es autónomo:

1. Instala los paquetes de `packages/system.txt` que aplican al perfil
   (detecta apt/pkg/brew).
2. Instala toolchains (rustup, uv, go), binarios (helix, herdr, lazygit,
   lazysql, ...) y, en el perfil vps, la infra (AWS/Terraform/sops/GCP), el
   agente (Pi + gentle-ai, con skills delegadas a prim-skills), moshi-hook, y
   los servicios de OS que necesita (SSH + linger).
3. Instala `chezmoi` y aplica los dotfiles de `home/` para el perfil.

Es **idempotente**: cada herramienta se instala solo si falta, así que puedes
volver a correrlo sin romper nada.

---

## Python por proyecto (uv + direnv)

Python **no** se instala a nivel de sistema. Cada proyecto usa `uv`:

```bash
cd mi-proyecto
uv init            # crea pyproject.toml
uv add polars      # añade dependencias -> uv.lock
uv run python ...  # ejecuta en el .venv del proyecto
```

`direnv` complementa a uv: activa el `.venv` al entrar a la carpeta (para que el
LSP de Helix vea las dependencias) y aísla variables de entorno y credenciales
cloud por proyecto (p. ej. una cuenta de gcloud por proyecto con
`CLOUDSDK_ACTIVE_CONFIG_NAME`). Rust (Cargo) y Go (módulos) ya aíslan sus
dependencias de forma nativa; direnv ahí solo sirve para variables de entorno.

---

## Secretos (sops + age)

```bash
sops --encrypt --age <age-public-key> secreto.env > secreto.enc.env  # cifrar
sops --decrypt secreto.enc.env > ~/.secrets/secreto.env              # descifrar
```

`sops` y `age` se instalan en el perfil VPS. La clave privada age vive fuera del
repo (nunca se commitea).

---

## Datos (Cloudflare R2)

Los datos persistentes viven en R2 (S3-compatible), accedidos con AWS CLI o
librerías S3 apuntando al endpoint de R2. El VPS no guarda estado de datos: R2
es la fuente de verdad, y por eso el VPS es desechable y reproducible.

---

## CI

`.github/workflows/build-installer.yml` compila `devlab-install` para
x86_64-linux y aarch64-linux en cada push a `installer/**` y lo publica como
prerelease `latest` con su sha256.

`.github/workflows/validate.yml` valida en cada push/PR:

- `shellcheck` sobre `install.sh`.
- Render de las plantillas chezmoi para ambos perfiles `dc1` y `vps`.
