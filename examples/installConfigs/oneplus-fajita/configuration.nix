{
  pkgs,
  ...
}:
{
  imports = [
    ./disko-config.nix
  ];

  vanilla-mobile.installer = {
    enable = true;
    buildSystem = "x86_64-linux";
  };

  vanilla-mobile.device.oneplus-fajita.enable = true;

  vanilla-mobile.cache.enable = true;

  nixpkgs.config.allowUnfreePackages = [
    "oneplus-fajita-firmware"
  ];

  system.stateVersion = "26.05";
}
