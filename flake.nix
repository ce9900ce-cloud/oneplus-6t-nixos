{
  description = "Run standard NixOS on your mobile devices!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, flake-utils, disko, ... }@inputs:
    let
      getDefault =
        system:
        import ./default.nix {
          flake = self;
          inherit inputs system;
        };

      # OnePlus 6T NixOS configuration — buildable via GitHub Actions
      oneplus-fajita-system = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          disko.nixosModules.disko
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
      # Standalone buildable configuration — not wrapped in eachDefaultSystem
      # so it stays aarch64-linux regardless of build host.
      nixosConfigurations.oneplus-fajita = oneplus-fajita-system;
    };
}
