self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.vanilla-mobile.camera;
in
{
  options.vanilla-mobile.camera = {
    enable = lib.mkEnableOption "camera support (libcamera + megapixels)";
  };

  config = lib.mkIf cfg.enable {
    # Load kernel camera modules at boot
    boot.kernelModules = [
      "qcom_camss"        # Qualcomm Camera Subsystem (ISP)
      "imx371"            # Front camera
      "imx376"            # Rear wide camera
      "imx519"            # Rear main camera
      "lc898217xc"        # Camera autofocus actuator
    ];

    # Install libcamera with qcam test app
    environment.systemPackages = with pkgs; [
      # Camera pipeline
      (libcamera.override { withQcam = true; })  # libcamera with qcam test app

      # Camera apps
      megapixels                           # GTK camera app (uses libcamera)
      libcamera-iq
      libdng                               # DNG/RAW image format support
      libmegapixels                        # Shared lib for megapixels
    ];

    # udev rules for camera device access
    services.udev.extraRules = ''
      # libcamera / camss video devices
      SUBSYSTEM=="video4linux", GROUP="video", MODE="0660"
      SUBSYSTEM=="media", GROUP="video", MODE="0660"
      SUBSYSTEM=="i2c-dev", GROUP="video", MODE="0660"
      SUBSYSTEM=="v4l2_capture", GROUP="video", MODE="0660"
      SUBSYSTEM=="v4l2_subdev", GROUP="video", MODE="0660"
    '';

    # Add user to video group for camera access
    users.users.${config.vanilla-mobile.user.name or "nixos"}.extraGroups = [ "video" ];

    # libcamera camss pipeline uses media controller;
    # no systemd service needed as libcamera auto-discovers
    # the media graph topology at runtime.
    #
    # If cameras are not detected automatically, try:
    #   media-ctl -d /dev/media0 -p
    # to enumerate the media graph, then manually configure
    # sensor -> CSI -> ISP routing with:
    #   media-ctl -d /dev/media0 -l '"imx371 2-001a":0 -> "csiphy0":0 [1]'
    #   media-ctl -d /dev/media0 -V '"imx371 2-001a":0 [fmt:SRGGB10_1X10/1280x720]'
  };
}
