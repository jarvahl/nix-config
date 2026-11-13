{ ... }:
{
  den.aspects.foot.hjem =
    { config, lib, ... }:
    {
      wayland.windowManager.hyprland.settings.bind =
        lib.mkIf config.wayland.windowManager.hyprland.enable
          (
            with lib.generators;
            [
              {
                _args = [
                  "SUPER + Q"
                  (mkLuaInline ''hl.dsp.exec_cmd("foot")'')
                ];
              }
            ]
          );

      rum.programs.foot = {
        enable = true;
        settings.main = {
          font = "FiraCode Nerd Font:size=9";
          pad = "16x16";
        };
      };
    };
}
