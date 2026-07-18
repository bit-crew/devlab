{
  description = "Modular Home Manager configuration for Tablet and VPS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    user-config = {
      url = "https://config.your-domain.com/config.json";
      from = "direct";
    };
  };

  outputs = { nixpkgs, home-manager, agenix, user-config, ... }:
    let
      pkgs-x86 = nixpkgs.legacyPackages."x86_64-linux";
      pkgs-arm = nixpkgs.legacyPackages."aarch64-linux";
      configData = builtins.fromJSON user-config;
    in {
      homeConfigurations = {
        server = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs-x86;
          extraSpecialArgs = { inherit configData; };
          modules = [
            ./nix/server.nix
            agenix.homeManagerModules.default
          ];
        };

        tablet = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs-arm;
          extraSpecialArgs = { inherit configData; };
          modules = [
            ./nix/tablet.nix
            agenix.homeManagerModules.default
          ];
        };
      };
    };
}
