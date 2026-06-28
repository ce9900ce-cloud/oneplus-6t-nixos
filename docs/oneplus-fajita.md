# OnePlus 6T (oneplus-fajita)

## Setup Instructions

These instructions require `fastboot`. You can access it with `nix-shell -p android-tools`.
If you have trouble getting some `fastboot` commands to work, you may need to try other
USB cables/ports. Plugging into a multi-port external USB hub has worked for me.

> 💡 **No Nix locally?** Push this repo to GitHub and run the CI workflow.
> The `.github/workflows/build.yml` will cross-compile everything online for you.
> See [README → Online Build](../README.md#online-build-github-actions) for details.

### Prep Work

Before installing Linux on the OnePlus 6T:

- **Unlock the bootloader.** Follow the official OnePlus instructions or
  [LineageOS guide](https://wiki.lineageos.org/devices/fajita/install).
  Note: Unlocking requires a fresh boot of OxygenOS, and wipes the device.
- **Update your device's firmware** to the latest available OxygenOS version
  (Android 11 / 12). The modem firmware is critical for baseband functionality.
- **Know your device variant.** Only the global version (fajita) is supported.
  T-Mobile variant (fajitatmo) has a locked bootloader.

### Installing NixOS

Like with the POCO F1, installing NixOS on the OnePlus 6T uses U-Boot to create
a UEFI boot environment. The process is:

1. Create a simple "install" NixOS configuration for the device.
2. Use `disko` to build the configuration into flashable images.
3. Flash U-Boot to the phone.
4. Flash the NixOS configuration images to the phone.
5. Boot into NixOS and customize your config.

### NixOS Config

Copy `examples/installConfigs/oneplus-fajita` from this repository
into your NixOS configuration.

Now:
- Add `vanilla-mobile-nixos` and `disko` to your inputs.
- Add the `oneplus-fajita` example as a NixOS configuration.
- Import the `vanilla-mobile` and `disko` modules in that config.

Here's a simple example of that for flakes:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    vanilla-mobile-nixos.url = "github:vanilla-mobile-nixos/vanilla-mobile-nixos";
    disko = {
      url = "github:JuneStepp/disko/virtual-devices-option";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, vanilla-mobile-nixos, disko, ... }: {
    nixosConfigurations.oneplus-fajita = nixpkgs.lib.nixosSystem {
      modules = [
        vanilla-mobile-nixos.nixosModules.vanilla-mobile
        disko.nixosModules.disko
        ./hosts/oneplus-fajita/configuration.nix
      ];
    };
  };
}
```

For Home Manager users, there's an additional `homeManagerModules.vanilla-mobile` module
available.

## NixOS Image Building

The OnePlus 6T is an aarch64 device. If you don't have an aarch64 computer to build
the installer on, you'll have to enable binfmt emulation:

```nix
boot.binfmt.emulatedSystems = [
   (lib.mkIf (pkgs.stdenv.hostPlatform.system != "aarch64-linux") "aarch64-linux")
];
```

If you enable binfmt, you'll also need to set `vanilla-mobile.installer.buildSystem`
in your phone config to the output of:
`nix-instantiate --eval --expr "(import <nixpkgs> {}).stdenv.system"`

### Enable binary cache

Add to your PC's Nix configuration:

```nix
nix.settings = {
  trusted-substituters = [
    "https://vanilla-mobile-nixos.cachix.org"
  ];
  trusted-public-keys = [
    "vanilla-mobile-nixos.cachix.org-1:nicMQxxTD4n6PM9dCvylqsCOCA6M2C6gybbCKrei8AQ="
  ];
};
```

Then build with `--option extra-substituters https://vanilla-mobile-nixos.cachix.org`.

### Build the images

```bash
nix build .#nixosConfigurations.oneplus-fajita.config.system.build.diskoImagesScript
```

If using LUKS encryption, run the script with the password:

```bash
bash -c 'read -s -p "LUKS Password: " p; tmp=$(mktemp); trap "rm \"$tmp\"" EXIT; echo "$p" > "$tmp"; ./result --pre-format-files "$tmp" /tmp/nixos-root.key'
```

This should create two images: `nixos-boot.raw` and `nixos-root.raw`.

### U-Boot

Build the U-Boot boot image:

```bash
nix build .#nixosConfigurations.oneplus-fajita.config.vanilla-mobile.deviceInfo.uboot
```

Then flash it to the phone:

1. Reboot the phone into fastboot mode (Power + Vol Up when off, or `adb reboot bootloader`)
2. Flash U-Boot:

```bash
fastboot erase dtbo_a
fastboot erase boot_a
fastboot flash boot_a result/u-boot.img
```

3. Do NOT reboot yet.

### NixOS Image Flashing

Flash the images:

```bash
fastboot flash system_a nixos-boot.raw
fastboot flash userdata nixos-root.raw
```

The `userdata` flash may take several minutes. Be patient and don't interrupt it.

After flashing, set the active slot and reboot:

```bash
fastboot set_active a
fastboot reboot
```

The first boot will take a while. DO NOT manually reboot or interrupt.

### SSH Access

Once booted, you should be able to SSH over USB:

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o PasswordAuthentication=yes -o PreferredAuthentications=password \
  nixos@172.16.42.1
```

If you want persistent SSH over USB in your production config:

```nix
services.openssh = {
  enable = true;
  openFirewall = false;
  listenAddresses = [
    { addr = config.vanilla-mobile.usb-gadget.network.serverAddress; }
  ];
};
```

After SSH'ing in, switch to USB developer mode by selecting "Developer" in the
USB notification on the phone.

### Starter Config

First, remove the `vanilla-mobile.installer` section from your configuration.
Then add your desktop environment and apps. See [What software should I use?](./software-info.md)
for information and example configs.

Once you've created your starter config, deploy it:

```bash
nixos-rebuild boot --flake .#oneplus-fajita --target-host "root@172.16.42.1"
```

### Troubleshooting

- **Phone freezes during boot?** Hold the power button to force restart.
- **Can't connect via SSH?** Make sure USB developer mode is enabled on the phone.
- **WiFi issues?** Try connecting to a 2.4GHz network. The 5Ghz band may be unstable
  on some kernel versions. You can force NetworkManager profiles to use `bg` band:
  ```nix
  networking.networkmanager.ensureProfiles.profiles.<NAME>.wifi.band = "bg";
  ```
- **Modem not working?** Check that the phone has the latest OxygenOS firmware.
  If 4G/SMS still don't work, try cold rebooting (power off completely, not just restart).
- **Unbricking?** If you lose fastboot, you can use the EDL (Emergency Download) mode.
  See: <https://github.com/pocketblue/oneplus-sdm845-unbrick>

## Hardware Status

| Component           | Status |
|---------------------|--------|
| Display/Touch       | ✅ Working |
| WiFi                | ✅ Working |
| Bluetooth           | ✅ Working |
| Audio (speaker)     | ⚠️ Untested |
| Audio (headset)     | ⚠️ Untested |
| Microphone          | ⚠️ Untested |
| Modem (4G)          | ⚠️ Untested (should work) |
| SMS                 | ⚠️ Untested (should work) |
| Phone calls         | ⚠️ Untested |
| GPS                 | ⚠️ Untested |
| Camera (rear)       | ❌ Not yet supported |
| Camera (front)      | ❌ Not yet supported |
| Fingerprint sensor  | ❌ Not yet supported |
| Sensors (accel/prox)| ⚠️ Untested |

This device is **implemented but untested**. If you have a OnePlus 6T and
test any of these components, please report your findings by opening an issue
or pull request!
