{
  pkgs,
  ...
}:
{
  imports = [
    ./disko-config.nix
  ];

  # Remove this after the initial flash.
  vanilla-mobile.installer = {
    enable = true;
    # If using binfmt, set `buildSystem` to the output of:
    # `nix-instantiate --eval --expr "(import <nixpkgs> {}).stdenv.system"`
    # buildSystem =
  };

  vanilla-mobile.device.oneplus-fajita.enable = true;

  # Use the cache, so you don't have to spend hours building kernels.
  vanilla-mobile.cache.enable = true;

  # Allow using the phone's firmware.
  nixpkgs.config.allowUnfreePackages = [
    "oneplus-fajita-firmware"
  ];

  system.stateVersion = "26.05";
}
