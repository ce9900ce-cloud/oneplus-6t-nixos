{
  pkgs,
  ...
}:
{
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

  # Filesystem — partition labels must match what fastboot flashes
  # Boot: 2GB FAT32, label=nixos-boot
  # Root: 4GB ext4 (or LUKS+ext4), label=nixos-root
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-root";
    fsType = "ext4";
    autoResize = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/nixos-boot";
    fsType = "vfat";
  };
}
