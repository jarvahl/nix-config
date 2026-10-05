{ ... }:
{
  den.aspects.foot.hjem =
    { config, lib, ... }:
    {
      rum.programs.foot = {
        enable = true;
        settings.main = {
          pad = "16x16";
          font = "FiraCode Nerd Font:size=9";
        };
      };

      rum.desktops.hyprland.settings.bind = lib.mkIf config.rum.desktops.hyprland.enable [
        "SUPER, Q, exec, foot"
      ];
    };
}
