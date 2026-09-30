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
Desde cualquier dispositivo (Linux, Mac, WSL, Android/Termux):

```bash
curl -fsSL https://codeberg.org/jdmb/devlab/raw/branch/main/setup.sh | sh
```

`setup.sh` pregunta qué configurar:

1. **Esta máquina como cliente (dc1)** — instalará el entorno local y enlazará
   este cliente al VPS generando su propia clave SSH. (En desarrollo.)
2. **Un VPS remoto (vps)** — pregunta IP y usuario del VPS, se conecta por SSH
   con la password (la temporal de OVH), clona el repo en el VPS y corre
   `bootstrap.sh vps`. Se puede hacer desde cualquier PC; no instala claves SSH.

No requiere clonar nada ni tener Python: solo `sh` (y `ssh` para el VPS).
También puedes pasar el rol como argumento: `sh setup.sh dc1` o `sh setup.sh vps`.

También funciona si ya clonaste el repo: `sh setup.sh`.

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

- **Ambos:** git, openssh, zsh, curl, jq, helix, zellij, lazygit, yazi, ripgrep,
  fd, fzf, bat, zoxide, eza, atuin, starship, chezmoi, uv, Python (vía uv),
  rustup + rust-analyzer.
- **Solo VPS:** JDK (PySpark para tests), Docker, AWS CLI, Terraform, sops, age,
  toolchain C/C++ + clangd.

Lo que está en el apt oficial de Debian se instala por apt (`packages/apt.txt`);
las herramientas modernas en Rust y algunos binarios (helix, zellij, lazygit,
terraform, aws-cli, sops) se instalan por cargo/binario en un `run_once`.

---

## Estructura del repositorio

```text
devlab/
├── setup.sh                  # punto de entrada unico (cliente o VPS)
├── bootstrap.sh              # server-setup: apt + chezmoi init --apply
├── docs/
│   └── vps-ovh.md            # compra manual del VPS y flujo de despliegue
├── packages/
│   ├── apt.txt               # paquetes Debian por perfil (both|dc1|vps)
│   └── cargo.txt             # componentes rustup + herramientas cargo
├── home/                     # source de chezmoi
│   ├── .chezmoi.toml.tmpl
│   ├── .chezmoidata.yaml
│   ├── dot_gitconfig.tmpl
│   ├── dot_zshrc.tmpl
│   ├── dot_config/           # helix, zellij, lazygit, atuin, ghostty
│   ├── run_once_10-install-toolchains.sh.tmpl  # rustup + uv + cargo
│   ├── run_once_15-install-binaries.sh.tmpl    # helix, zellij, terraform...
│   └── run_once_20-clone-agent.sh.tmpl         # clona steering (solo VPS)
├── .github/workflows/        # CI: shellcheck + render de plantillas
└── README.md
```

---

## bootstrap.sh (dentro del VPS)

`setup.sh` lo ejecuta por ti, pero también puedes correrlo manual:

```bash
./bootstrap.sh dc1   # máquina local
./bootstrap.sh vps   # servidor
```

1. Instala los paquetes de `packages/apt.txt` que aplican al perfil.
2. Crea symlinks `fd`->`fdfind` y `bat`->`batcat` (nombres de Debian).
3. Instala `chezmoi` en `~/.local/bin` si falta.
4. Ejecuta `chezmoi init --apply`, que aplica dotfiles y corre los `run_once`
   (rustup, uv, cargo, binarios y, en VPS, clona el repo de steering).

Es **idempotente**: puedes volver a correrlo sin romper nada.

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

`.github/workflows/validate.yml` valida en cada push/PR:

- `shellcheck` sobre `bootstrap.sh`.
- Render de las plantillas chezmoi para ambos perfiles `dc1` y `vps`.
