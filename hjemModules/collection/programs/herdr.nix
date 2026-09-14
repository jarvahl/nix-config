{ config, lib, pkgs, ... }:
let
  cfg = config.programs.herdr;
in
{
  options.programs.herdr = {
    enable = lib.mkEnableOption "Herdr";

    integrations.pi.enable = lib.mkEnableOption "Herdr integration for Pi";
  };

  config = lib.mkIf cfg.enable {
    packages = [ pkgs.herdr ];

    files.".config/herdr/config.toml".text = ''
      onboarding = false

      [theme]
      name = "catppuccin"

      [theme.custom]
      sidebar_bg = "#181825"
      panel_bg = "#181825"
    '';

    programs.pi.skills.herdr = lib.mkIf cfg.integrations.pi.enable
      "${pkgs.herdr.src}/skills/herdr";
  };
}
