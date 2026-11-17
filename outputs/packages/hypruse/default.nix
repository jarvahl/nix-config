{ inputs, pkgs }:

inputs.hypruse.packages.${pkgs.system}.hypruse.overrideAttrs (_: {
  doCheck = false;
  doInstallCheck = false;
  dontCheck = true;
})
