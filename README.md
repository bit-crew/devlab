# Modular Dev Setup (Nix & Dotfiles)

Declarative development environment configured for Data Engineering (PySpark, AWS, DuckDB), modal editing (Helix), and terminal multiplexing (Zellij) managed via **Nix Flakes & Home Manager on Void Linux**.

> **NOTE**: This configuration is designed for **Void Linux** with **Nix + Home Manager**. It is NOT compatible with NixOS.

---

## Repository Structure

```text
dev-setup/
├── .github/workflows/   # CI validation
├── dotfiles/           # Configuration files managed by Home Manager / GNU Stow
│   ├── ghostty/       # GPU-accelerated terminal configuration
│   ├── helix/         # Text editor configuration & LSP setups
│   ├── zellij/        # Terminal multiplexer configuration
│   ├── lazygit/       # Git TUI configuration
│   ├── atuin/         # Shell history configuration
│   └── Makefile       # Fallback installer/stower for non-Nix environments
├── nix/               # Nix Home Manager modules
│   ├── common.nix    # Shared system packages, Git, Zsh, Starship & LSPs
│   ├── server.nix    # Server profile (Data Engineering tools, JVM, UV, Agent cloning)
│   └── tablet.nix    # Tablet profile (Offline/local lightweight interface)
├── secrets/           # Age-encrypted secrets (see secrets/README.md)
├── flake.nix         # Main Flake entrypoint defining profile configurations
└── README.md         # This guide
```

---

## Target Systems

| Profile | Description | Architecture |
|---------|-------------|--------------|
| `server` | VPS / Data Engineering server | x86_64-linux |
| `tablet` | Local ARM64 tablet (offline-first) | aarch64-linux |

---

## Configuration Storage (Cloudflare Access + GitHub OAuth)

This setup uses **zero manual configuration** by fetching user config from a Cloudflare Access protected endpoint.

### Architecture
```
┌─────────────────┐    Cloudflare Access     ┌──────────────────┐
│  Your Device    │◄─── GitHub OAuth ─────►│  Private Config  │
│  (no config)   │                        │  (Gist / Bucket)  │
└─────────────────┘                        └──────────────────┘
```

### Setup

1. Create a private Gist or use Cloudflare Access tunnel
2. Protect the URL with GitHub OAuth (require specific GitHub account)
3. Create `config.json`:
```json
{
  "git": { "userName": "Your Name", "userEmail": "your@email.com" },
  "home": { "username": "youruser", "homeDirectory": "/home/youruser" }
}
```
4. Update `flake.nix` with your config URL

---

## Secrets Management (Agenix)

Age-encrypted secrets for sensitive data (API keys, tokens, credentials). Cifrados en git, descifrados solo en tu máquina.

### Architecture
```
┌─────────────────┐
│  secrets/*.age  │  ← Encrypted with your age public key (safe in git)
│  (in git)       │
└─────────────────┘
        ▼
┌─────────────────┐
│  ~/.secrets/    │  ← Decrypted at activation time (never in git)
│  (home dir)     │
└─────────────────┘
```

### 1. Generate age key

```bash
nix run github:ryantm/agenix -- --generate
mkdir -p ~/.config/age
cp your-age-key.txt ~/.config/age/keys.txt
```

> NEVER commit `keys.txt`. Backup offline (USB, paper).

### 2. Create secrets

```bash
nix run github:ryantm/agenix -- -e secrets/aws-credentials.age
```

Write plaintext content, save (Ctrl+D). The file is stored encrypted.

### 3. Reference in Nix

```nix
# In server.nix
age = {
  publicKey = "age1your-public-key...";
  secrets = {
    aws-credentials.file = ./secrets/aws-credentials.age;
    github-token.file = ./secrets/github-token.age;
  };
};
```

### 4. Activate

```bash
home-manager switch --flake .#server
```

Secrets are decrypted to `~/.secrets/` automatically.

### Example structure

```
secrets/
├── config.json              # Example template (not a secret)
├── aws-credentials.age      # AWS keys (encrypted)
├── github-token.age         # GitHub PAT (encrypted)
└── api-keys.age             # Other API keys (encrypted)
```

---

## Deployment

### Deploying the Profile
Run the following commands to initialize and apply the Home Manager configuration using Nix Flakes:

```bash
# 1. Initialize Home Manager
nix run home-manager/master -- init --flake .#server

# 2. Build and activate the profile
home-manager switch --flake .#server
```
*(Replace `#server` with `#tablet` if deploying to a local/ARM64 client tablet).*

Once activated:
* Home Manager will symlink all configuration files inside `dotfiles/` to `~/.config/` natively using `xdg.configFile`.
* Standard LSPs (`pyright`, `ruff`, `taplo`, `yaml-language-server`, `marksman`) will be installed and mapped to Helix automatically.

---

## CI Validation

This repository includes a GitHub Actions workflow (`.github/workflows/validate.yml`) that validates:
- Flake evaluates correctly
- Both server and tablet configurations build without errors

---

## Agent Steering Integration
Upon activation of the `server` profile:
* Git will automatically clone the public steering repository `https://github.com/jdmarinb/agent.git` into `~/.agent`.
* Any agent (like **Antigravity CLI / agy**, Claude Code, Kiro, etc.) running on the server will automatically discover and load the Data Engineering skills defined in `~/.agent/AGENT.md`.

---

## Fallback Stow Deployment (Non-Nix Systems)
If you are on a system where Nix is not available (e.g., standard Ubuntu/macOS) and want to deploy the dotfiles manually:

```bash
cd dotfiles
make install
```
*This installs standard binaries manually to `~/.local/bin` and uses `stow` to link the dotfiles to `~/.config`.*
