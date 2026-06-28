self:
{
  config,
  lib,
  ...
}:
let
  cfg = config.vanilla-mobile.device.oneplus-fajita;
in
{
  options.vanilla-mobile.device.oneplus-fajita = {
    enable = lib.mkEnableOption "OnePlus 6T (oneplus-fajita / sdm845)";
  };

  config = lib.mkIf cfg.enable {
    warnings =
      if !config.boot.loader.systemd-boot.enable then
        [
          ''
            systemd-boot is disabled. oneplus-fajita has currently only
            been configured/tested for systemd-boot.
          ''
        ]
      else
        [ ];

    vanilla-mobile = {
      deviceInfo = {
        name = "OnePlus 6T";
        codename = "oneplus-fajita";
        manufacturer = "OnePlus";
        dtb = "qcom/sdm845-oneplus-fajita";
        imageSectorSize = 4096;
        firmware = self.packages.oneplus-fajita-firmware;
        uboot = self.packages.ubootPackages."oneplus-fajita-boot-image";
      };
      soc.sdm845.enable = true;
    };

    boot = {
      kernelParams = [
        # Look for the firmware we add to `extra-firmware`.
        "firmware_class.path=/extra-firmware"

        # FIXME: console=ttyMSM0 workaround for display race condition.
        # See: <https://gitlab.freedesktop.org/drm/msm/-/issues/46>
        "console=ttyMSM0,115200"
      ];
      initrd = {
        # Based on
        # <https://gitlab.postmarketos.org/postmarketOS/pmaports/-/blob/master/device/community/device-oneplus-fajita/modules-initfs>
        kernelModules = [
          "gpi"
          "i2c_qcom_geni"
          "qcom_smbx"
          "rmi_core"
          "rmi_i2c"
          "qcom_spmi_haptics"
        ];

        systemd.enable = true;
        systemd.storePaths =
          map
            (fw: {
              source = "${config.hardware.firmware}/lib/firmware/${fw}.zst";
              target = "/extra-firmware/${fw}.zst";
            })
            [
              # GPU and modem firmware for initramfs.
              # Based on:
              # <https://salsa.debian.org/DebianOnMobile-team/qcom-phone-utils/-/blob/debian/latest/initramfs-tools/hooks/qcom-firmware>.
              "qcom/sdm845/oneplus6/adsp.mbn"
              "qcom/sdm845/oneplus6/cdsp.mbn"
              "qcom/sdm845/oneplus6/ipa_fws.mbn"
              "qcom/sdm845/oneplus6/a630_zap.mbn"
              "qcom/sdm845/oneplus6/slpi.mbn"

              # WiFi/Bluetooth firmware (WCN3990).
              "ath10k/WCN3990/hw1.0/board-2.bin"
              "qca/crbtfw21.tlv"
              "qca/crnv21.bin"

              # GPU firmware.
              "qcom/a630_sqe.fw"
              "qcom/a630_gmu.bin"
            ];
      };
    };

    services.udev.extraRules = ''
      # Accelerometer mount matrix for iio-sensor-proxy.
      # Source: <https://gitlab.postmarketos.org/postmarketOS/pmaports/-/raw/master/device/community/device-oneplus-fajita/81-libssc-oneplus-fajita.rules>
      SUBSYSTEM=="iio", ENV{MODALIAS}=="iio:device*", ATTR{sensors_mount_matrix}="0,-1,0,0,0,-1,1,0,0"
    '';

    # hexagonrpcd firmware directory for fajita.
    # Based on pmOS: <https://gitlab.postmarketos.org/postmarketOS/pmaports/-/raw/master/device/community/device-oneplus-fajita/hexagonrpcd.confd>
    # hexagonrpcd auto-discovers firmware via /share/qcom symlinks,
    # so we don't need a device-specific config file.
    # The symlink "fajita -> oneplus6" in the firmware package handles this.

    # q6voiced configuration for fajita.
    # Based on pmOS: <https://gitlab.postmarketos.org/postmarketOS/pmaports/-/raw/master/device/community/device-oneplus-fajita/q6voiced.conf>
    services.q6voiced = {
      enable = true;
      settings = {
        q6voice_card = 0;
        q6voice_device = 6;
      };
    };

  };
}
