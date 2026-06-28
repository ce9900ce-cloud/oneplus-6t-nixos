{
  description = "Run standard NixOS on your mobile devices!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils, ... }@inputs:
    let
      getDefault =
        system:
        import ./default.nix {
          flake = self;
          inherit inputs system;
        };

      # OnePlus 6T NixOS configuration
      oneplus-fajita-system = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          self.nixosModules.vanilla-mobile
          ./examples/installConfigs/oneplus-fajita
        ];
      };
    in
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        default = getDefault system;
      in
      {
        packages = flake-utils.lib.flattenTree default.packages;
      }
    ))
    // (flake-utils.lib.eachDefaultSystemPassThrough (
      system:
      let
        default = getDefault system;
      in
      {
        inherit (default) nixosModules homeManagerModules;
      }
    ))
    // {
      nixosConfigurations.oneplus-fajita = oneplus-fajita-system;
    };
}