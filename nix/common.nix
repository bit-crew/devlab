{ pkgs, ... }: {
  home.username = "johanmarin"; # Ajustar según sea necesario
  home.homeDirectory = "/home/johanmarin";
  home.stateVersion = "23.11";

  # Herramientas base en ambos sistemas
  home.packages = with pkgs; [
    git
    atuin
    zoxide
    starship
    ripgrep
    fd
    bat
    fzf
    # Clipboard providers para Helix/Nvim
    xclip
    wl-clipboard
  ];

  # Configuración declarativa de programas comunes
  programs.git = {
    enable = true;
    userName = "Johan Marin";
    userEmail = "tu@email.com"; # Cambiar por el real
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "hx";
    };
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
      update_check = false;
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      lg = "lazygit";
      hx = "helix";
      ".." = "cd ..";
    };
    initExtra = ''
      eval "$(starship init zsh)"
    '';
  };

  programs.starship = {
    enable = true;
  };
}
