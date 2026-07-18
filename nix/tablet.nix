{ pkgs, ... }: {
  imports = [ ./common.nix ];

  # Perfil Tablet: edición offline, sincronización por git al reconectar
  home.packages = with pkgs; [
    # Editores
    helix
    neovim

    # Terminal
    zellij
    lazygit
    yazi

    # Data (exploración local)
    sc-im
  ];

  programs.zellij = {
    enable = true;
  };
}
