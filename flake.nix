{
  description = "Modular Home Manager configuration for Tablet and VPS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux"; # Ajustar a aarch64-linux para tablet si es necesario
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations = {
        # Perfil para el VPS (Servidor de Datos)
        server = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./nix/server.nix ];
        };

        # Perfil para la Tablet (Interfaz Offline)
        tablet = home-manager.lib.homeManagerConfiguration {
          # Para tablet solemos necesitar aarch64-linux
          pkgs = nixpkgs.legacyPackages."aarch64-linux";
          modules = [ ./nix/tablet.nix ];
        };
      };
    };
}
