{ pkgs, lib, config, configData, ... }: {
  home.stateVersion = "23.11";
  home.username = configData.home.username;
  home.homeDirectory = configData.home.homeDirectory;

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
    eza
    btop
    tealdeer
    # Clipboard providers para Helix
    xclip
    wl-clipboard

    # Language Servers (LSPs) & Formaters para Helix
    pyright
    ruff
    taplo
    yaml-language-server
    marksman
    glow
  ];

  # Gestión declarativa de dotfiles mediante Home Manager
  xdg.enable = true;
  xdg.configFile = {
    "helix/config.toml".source = ../dotfiles/helix/config.toml;
    "helix/languages.toml".source = ../dotfiles/helix/languages.toml;
    "zellij/config.kdl".source = ../dotfiles/zellij/config.kdl;
    "lazygit/config.yml".source = ../dotfiles/lazygit/config.yml;
    "atuin/config.toml".source = ../dotfiles/atuin/config.toml;
    "ghostty/config".source = ../dotfiles/ghostty/config;
  };

  # Configuración declarativa de programas comunes
  programs.git = {
    enable = true;
    userName = configData.git.userName;
    userEmail = configData.git.userEmail;
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
