let
  vmn = import ./default.nix {};
  pkgsCross = import vmn.inputs.nixpkgs {
    system = "aarch64-linux";
    config.allowUnsupportedSystem = true;
  };
in
vmn.packages.ubootPackages.oneplus-fajita-boot-image
