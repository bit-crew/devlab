{ pkgs, lib, config, ... }: {
  imports = [ ./common.nix ];

  # ============================================
  # AGENIX (Void Linux + Home Manager)
  # ============================================
  # En Void Linux, agenix se configura via home-manager module
  age = {
    # Reemplaza con tu clave pública age
    # Genera con: nix run github:ryantm/agenix -- --generate
    publicKey = "age1example...";

    secrets = {
      # Ejemplo: credenciales AWS
      # Descomenta después de crear el archivo .age
      # aws-credentials = {
      #   file = ./secrets/aws-credentials.age;
      # };

      # Ejemplo: token de GitHub
      # github-token = {
      #   file = ./secrets/github-token.age;
      # };
    };
  };

  # Stack de Data Engineering y Herramientas del Servidor
  home.packages = with pkgs; [
    # Editores y Terminal
    helix
    neovim
    zellij
    lazygit
    eza
    btop
    yazi

    # Data Stack
    duckdb
    visidata
    sc-im
    ftv
    tidy-viewer

    # Cloud CLI
    awscli2
    terraform
    terragrunt

    # Languages & Dev
    uv
    jdk17 # Para PySpark
    python311
    rustc
    cargo
    bacon
    lldb

    # Debug
    python311Packages.pudb
    pytest
  ];

  # Configuración de Zellij para el servidor
  programs.zellij = {
    enable = true;
  };

  # KIRO_HOME apunta al repo agent/ para steering global
  home.sessionVariables = {
    KIRO_HOME = "$HOME/.agent";
  };

  # Pull de agent/ al iniciar shell (mantener steering actualizado)
  programs.zsh.initExtra = ''
    if [ -d "$HOME/.agent/.git" ]; then
      ${pkgs.git}/bin/git -C "$HOME/.agent" pull --ff-only --quiet 2>/dev/null &
    fi
  '';

  # Clonar automáticamente el repositorio de steering para los agentes
  home.activation = {
    cloneAgent = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "$HOME/.agent" ]; then
        ${pkgs.git}/bin/git clone ${configData.agent.repo} "$HOME/.agent"
      fi
    '';
    cloneLazyVim = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "$HOME/.config/nvim" ]; then
        ${pkgs.git}/bin/git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
        rm -rf "$HOME/.config/nvim/.git"
      fi
    '';
    installKiroCli = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if ! command -v kiro-cli &> /dev/null; then
        ${pkgs.curl}/bin/curl -fsSL https://cli.kiro.dev/install | ${pkgs.bash}/bin/bash
      fi
    '';
  };
}
