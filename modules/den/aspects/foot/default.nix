{ ... }:
{
  den.aspects.foot.hjem =
    { config, lib, ... }:
    {
      rum.desktops.hyprland.settings.bind = lib.mkIf config.rum.desktops.hyprland.enable [
        "SUPER, Q, exec, foot"
      ];

      rum.programs.foot = {
        enable = true;
        settings.main = {
          font = "FiraCode Nerd Font:size=9";
          pad = "16x16";
        };
      };
    };
}
