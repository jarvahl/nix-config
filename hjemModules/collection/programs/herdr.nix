{ config, lib, pkgs, ... }:
let
  cfg = config.programs.herdr;

in
{
  options.programs.herdr = {
    enable = lib.mkEnableOption "Herdr";

    integrations.pi.enable = lib.mkEnableOption "Herdr integration for Pi";

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional Herdr configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [ pkgs.herdr ];

    files.".config/herdr/config.toml".text = ''
      onboarding = false

      [ui]
      sidebar_start_collapsed = true
      sidebar_collapsed_mode = "compact"

      [theme]
      name = "vesper"

      ${cfg.extraConfig}
    '';

    programs.pi.skills.herdr = lib.mkIf cfg.integrations.pi.enable
      "${pkgs.herdr.src}/skills/herdr";

  };
}
