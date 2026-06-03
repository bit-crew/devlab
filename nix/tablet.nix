{ pkgs, ... }: {
  imports = [ ./common.nix ];

  # Zellij optimizado para local
  programs.zellij = {
    enable = true;
  };
}
