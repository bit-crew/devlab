# setup.ps1 - cliente devlab para Windows (PowerShell).
# Equivalente de setup.sh para Windows: instala el entorno de edicion con helix
# NATIVO en Windows usando scoop (sin admin, en el home del usuario). NO toca el
# .zshrc ni config de shell: Windows usa helix.exe directamente, no zsh.
#
# Uso (en PowerShell):
#   irm https://codeberg.org/jdmb/devlab/raw/branch/main/setup.ps1 | iex
# O con el repo clonado:
#   .\setup.ps1
#
# Que hace:
#   1. Instala scoop si falta (sin admin).
#   2. Anade buckets main/extras.
#   3. Instala CLI: helix, lazygit, ripgrep, fd, bat, fzf, delta, zoxide, starship.
#   4. Instala LSP/herramientas: rust-analyzer, taplo, nodejs, uv; basedpyright
#      (npm) y ruff (uv tool).
#   5. Aplica SOLO la config de helix en %APPDATA%\helix.

$ErrorActionPreference = "Stop"

function Log  { param($m) Write-Host "[setup] $m" -ForegroundColor Green }
function Warn { param($m) Write-Host "[setup] $m" -ForegroundColor Yellow }

# --- 1. scoop ---
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Log "Instalando scoop (sin admin)..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
} else {
    Log "scoop ya instalado."
}

# --- 2. buckets (helix y otros viven en 'extras') ---
Log "Asegurando buckets de scoop..."
scoop bucket add main   2>$null
scoop bucket add extras 2>$null

# --- 3. CLI + herramientas base ---
# Nombres del bucket main/extras. Si alguno falla, se continua con el resto.
$pkgs = @(
    "git", "jq", "ripgrep", "fd", "bat", "fzf", "delta", "zoxide",
    "starship", "lazygit", "helix", "rust-analyzer", "taplo",
    "nodejs-lts", "uv"
)
foreach ($p in $pkgs) {
    if (scoop list $p 2>$null | Select-String -Quiet $p) {
        Log "$p ya instalado."
    } else {
        Log "scoop install $p ..."
        try { scoop install $p } catch { Warn "Fallo instalar $p (continuo)" }
    }
}

# --- 4. LSP que no estan en scoop ---
# basedpyright via npm (nodejs ya instalado).
if (Get-Command npm -ErrorAction SilentlyContinue) {
    if (-not (Get-Command basedpyright-langserver -ErrorAction SilentlyContinue)) {
        Log "Instalando basedpyright (npm)..."
        try { npm install -g basedpyright } catch { Warn "Fallo basedpyright (continuo)" }
    }
    if (-not (Get-Command yaml-language-server -ErrorAction SilentlyContinue)) {
        Log "Instalando yaml-language-server (npm)..."
        try { npm install -g yaml-language-server } catch { Warn "Fallo yaml-language-server (continuo)" }
    }
}
# ruff via uv tool (global aislado).
if (Get-Command uv -ErrorAction SilentlyContinue) {
    if (-not (Get-Command ruff -ErrorAction SilentlyContinue)) {
        Log "Instalando ruff (uv tool)..."
        try { uv tool install ruff } catch { Warn "Fallo ruff (continuo)" }
    }
}

# --- 5. Config de helix (SOLO helix; nada de zsh) ---
# En Windows helix busca su config en %APPDATA%\helix.
$helixDst = Join-Path $env:APPDATA "helix"
New-Item -ItemType Directory -Force -Path $helixDst | Out-Null

# Localiza el repo: si el script corre desde el repo clonado, usa esa ruta;
# si no (via irm|iex), clona el repo en una carpeta temporal.
$repoHome = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "home\dot_config\helix"))) {
    $repoHome = Join-Path $PSScriptRoot "home"
} else {
    $tmp = Join-Path $env:TEMP "devlab-$(Get-Random)"
    Log "Clonando devlab para obtener la config de helix..."
    git clone --depth 1 https://codeberg.org/jdmb/devlab.git $tmp
    $repoHome = Join-Path $tmp "home"
}

$helixSrc = Join-Path $repoHome "dot_config\helix"
Log "Aplicando config de helix en $helixDst ..."
Copy-Item (Join-Path $helixSrc "config.toml") (Join-Path $helixDst "config.toml") -Force

# languages.toml es una plantilla chezmoi (.tmpl). En Windows no corremos chezmoi;
# tomamos el bloque base (perfil dc1) quitando las directivas de template.
# El bloque C/C++ es solo-VPS, asi que en Windows no aplica -> se omite.
$langTmpl = Get-Content (Join-Path $helixSrc "languages.toml.tmpl") -Raw
# Elimina lineas de template {{- if ... }} ... {{- end }} del bloque VPS y
# cualquier directiva {{ ... }}. Enfoque simple: cortar en el primer {{- if.
$langBase = ($langTmpl -split '\{\{-?\s*if')[0]
$langBase = [regex]::Replace($langBase, '\{\{.*?\}\}', '')
$langBase = $langBase.TrimStart()
# WriteAllText (no Set-Content) para NO escribir BOM: el BOM rompe el parser TOML.
[System.IO.File]::WriteAllText((Join-Path $helixDst "languages.toml"), $langBase)

Log "Cliente Windows listo. Abre una nueva terminal para que el PATH de scoop surta efecto."
Log "Edita con: hx"
