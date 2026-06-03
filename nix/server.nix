{ pkgs, lib, ... }: {
  imports = [ ./common.nix ];

  # Stack de Data Engineering y Herramientas del Servidor
  home.packages = with pkgs; [
    # Editores y Terminal
    helix
    zellij
    lazygit
    
    # Data Stack
    duckdb
    visidata
    ftv
    tidy-viewer
    
    # Languages & Dev
    uv
    jdk11 # Para PySpark
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

  # Clonar automáticamente el repositorio de steering para los agentes
  home.activation = {
    cloneAgent = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "$HOME/.agent" ]; then
        ${pkgs.git}/bin/git clone https://github.com/jdmarinb/agent.git "$HOME/.agent"
      fi
    '';
  };
}
