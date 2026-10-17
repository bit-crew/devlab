# devlab

Estación de trabajo de desarrollo reproducible, desplegable con un solo comando.

Entorno para Data Engineering (Polars, DuckDB, PySpark para tests, AWS), edición
modal (Helix) y multiplexado de terminal (Zellij), sobre **Debian 13**.

Sin Nix. La gestión es:

- **apt** — paquetes del sistema (Debian).
- **rustup** — toolchain de Rust (Rust, rust-analyzer).
- **uv** — Python por proyecto (`uv.lock`, `.venv`), no a nivel de sistema.
- **chezmoi** — dotfiles y configuración con plantillas por perfil.
- **Cloudflare R2** — datos persistentes.

---

## Despliegue con un solo comando

Punto de entrada único para ambos roles (tu máquina cliente o un VPS remoto).
Desde cualquier dispositivo Linux (incluido Android/Termux, arm64 — próximamente):

```bash
curl -fsSL https://raw.githubusercontent.com/bit-crew/devlab/main/install.sh | sh
```

`install.sh` descarga el binario precompilado `devlab-install` (publicado por
GitHub Actions en la release `latest`), verifica su checksum y lo ejecuta. Toda
la lógica de instalación vive en ese binario Rust.

Primero pregunta qué configurar:

1. **Cliente (este equipo, perfil dc1)** — baja y ejecuta el binario aquí.
2. **VPS remoto (perfil vps)** — pregunta IP y usuario del VPS, se conecta por
   SSH (con la password temporal de OVH) y corre `install.sh` allá en modo
   local con perfil `vps`. Se puede hacer desde cualquier PC; no instala claves
   SSH.

No requiere clonar nada ni tener Python: solo `sh` (y `ssh` para el VPS).
También puedes pasar el rol como argumento: `sh install.sh dc1` o
`sh install.sh vps`.

Hoy el binario se compila solo para `x86_64-linux`; otros objetivos
(Android/arm64, macOS, Windows) se añadirán cuando el CI los produzca.

**Modelo de responsabilidades:** configurar el VPS (con IP+usuario+password)
solo deja el servidor con el entorno instalado. Enlazar un cliente al VPS por
clave SSH es tarea de la configuración del cliente: cada máquina (tablet,
laptop) genera su clave y la registra en el VPS.

---

## Perfiles

| Perfil | Descripción | Rol |
|--------|-------------|-----|
| `dc1`  | Máquina local (Data Center 1) | Edición offline, se conecta al VPS por SSH |
| `vps`  | Servidor (OVHcloud, Debian) | Trabajo de datos: Polars/DuckDB, tests, Docker |

Reparto de herramientas (resumen):

- **Ambos:** git, openssh, zsh, curl, jq, helix, herdr, lazygit, yazi, ripgrep,
  fd, fzf, bat, zoxide, eza, atuin, starship, chezmoi, uv, Python (vía uv),
  rustup + rust-analyzer.
- **Solo VPS:** JDK (PySpark para tests), AWS CLI, Terraform, sops, age,
  GCP SDK, toolchain C/C++ + clangd, y el agente (Pi + gentle-ai).

Los paquetes del sistema se declaran en `packages/system.txt` (por perfil y
gestor: apt/pkg/brew); las herramientas en Rust y algunos binarios (helix,
herdr, lazygit, terraform, aws-cli, sops) los instala el binario
`devlab-install` desde release/cargo.

---

## Estructura del repositorio

```text
devlab/
├── install.sh                # punto de entrada: baja y ejecuta el binario
├── installer/                # binario Rust devlab-install (toda la logica)
│   ├── Cargo.toml
│   └── src/
├── docs/
│   └── vps-ovh.md            # compra manual del VPS y flujo de despliegue
├── packages/
│   ├── system.txt            # paquetes del sistema por perfil y gestor
│   └── cargo.txt             # componentes rustup + herramientas cargo
├── home/                     # source de chezmoi (dotfiles)
│   ├── .chezmoi.toml.tmpl
│   ├── .chezmoidata.yaml
│   ├── dot_gitconfig.tmpl
│   ├── dot_zshrc.tmpl
│   └── dot_config/           # helix, lazygit, atuin, ...
├── content/                  # steering/skills del agente (gentle/Pi)
├── .github/workflows/        # CI: build del binario + validacion
└── README.md
```

---

## El binario devlab-install

`install.sh` lo descarga y ejecuta por ti, pero el binario es autónomo:

1. Instala los paquetes de `packages/system.txt` que aplican al perfil
   (detecta apt/pkg/brew).
2. Instala toolchains (rustup, uv), binarios (helix, lazygit, ...) y, en el
   perfil vps, la infra (AWS/Terraform/sops/GCP) y el agente (Pi + gentle-ai).
3. Instala `chezmoi` y aplica los dotfiles de `home/` para el perfil.

Es **idempotente**: cada herramienta se instala solo si falta, así que puedes
volver a correrlo sin romper nada.

---

## Python por proyecto (uv)

Python **no** se instala a nivel de sistema. Cada proyecto usa `uv`:

```bash
cd mi-proyecto
uv init            # crea pyproject.toml
uv add polars      # añade dependencias -> uv.lock
uv run python ...  # ejecuta en el .venv del proyecto
```

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

## Steering del agente (solo VPS)

Al aplicar el perfil `vps`, `chezmoi` clona el repo de steering del agente en
`~/.agent` y `~/.zshrc` exporta `KIRO_HOME=$HOME/.agent`. El repo se actualiza en
background al abrir la shell.

---

## CI

`.github/workflows/build-installer.yml` compila el binario `devlab-install` en
cada push a `installer/**` y lo publica como prerelease `latest` con su sha256.

`.github/workflows/validate.yml` valida en cada push/PR:

- `shellcheck` sobre `install.sh`.
- Render de las plantillas chezmoi para ambos perfiles `dc1` y `vps`.
