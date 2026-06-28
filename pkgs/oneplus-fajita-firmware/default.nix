{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
  runCommand,
}:

stdenvNoCC.mkDerivation {
  pname = "oneplus-fajita-firmware";
  version = "0-unstable-2026-06-27";

  src = fetchFromGitLab {
    domain = "gitlab.com";
    owner = "sdm845-mainline";
    repo = "firmware-oneplus-sdm845";
    rev = "176ca713448c5237a983fb1f158cf3a5c251d775";
    hash = ""; # FIXME: set hash on first build (nix will tell you the correct one)
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    while IFS="" read -r _i || [ -n "$_i" ]; do
      install -Dm644 "$_i" "$out/$_i"
    done < "${./firmware.files}"

    # Files to be included to add sensor support.
    while IFS="" read -r _i || [ -n "$_i" ]; do
      install -Dm644 "$_i" "$out/''${_i#"./usr"}"
    done < "${./sensor.files}"

    # Create symlinks so hexagonrpcd can auto-discover firmware
    # for both oneplus-enchilada and oneplus-fajita.
    ln -s oneplus6 "$out/share/qcom/sdm845/OnePlus/enchilada"
    ln -s oneplus6 "$out/share/qcom/sdm845/OnePlus/fajita"

    runHook postInstall
  '';

  dontFixup = true;

  meta = {
    description = "Firmware for OnePlus 6 / 6T (enchilada / fajita)";
    homepage = "https://gitlab.com/sdm845-mainline/firmware-oneplus-sdm845";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.all;
  };
}
