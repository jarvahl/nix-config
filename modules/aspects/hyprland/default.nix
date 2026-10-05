{ ... }:
{
  den.aspects.hyperland = {
    hjem =
      { lib, pkgs, ... }:
      let
        workspaces = map toString (lib.range 1 9);
      in
      {
        rum.desktops.hyprland = {
          enable = true;

          settings = {
            monitor = ", preferred, auto, 1.0";

            general = {
              border_size = 0;
              gaps_in = 16;
              gaps_out = "0, 90, 48, 90";
            };

            decoration = {
              rounding = 14;
              rounding_power = 2;
              shadow = {
                enabled = true;
                range = 18;
                render_power = 3;
                color = "0xaa000000";
              };
            };

            misc = {
              background_color = "0xc8c0b4";
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              force_default_wallpaper = 0;
            };

            bind = [
              "SUPER, B, exec, ${pkgs.firefox}/bin/firefox"
              "SUPER, C, killactive"
              "SUPER, M, exit"
            ]
            ++ lib.concatMap (workspace: [
              "SUPER, ${workspace}, workspace, ${workspace}"
              "SUPER SHIFT, ${workspace}, movetoworkspace, ${workspace}"
            ]) workspaces;

            bindel = [
              ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%-"
              ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%+"
              ", XF86AudioLowerVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
              ", XF86AudioRaiseVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
              ", XF86AudioMute, exec, ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              ", XF86AudioMicMute, exec, ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            ];

            exec-once = "${pkgs.uwsm}/bin/uwsm finalize";
          };

          extraConfig = ''
            bind = SUPER SHIFT, F11, fullscreen, 1
            bind = SUPER SHIFT, F11, submap, focus-mode
            submap = focus-mode
            bind = SUPER, Escape, fullscreen, 0
            bind = SUPER, Escape, submap, reset
            submap = reset
          '';
        };
      };

    nixos = { pkgs, ... }: {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      services.udev.packages = [ pkgs.brightnessctl ];
    };

    user.extraGroups = [ "video" ];
  };
}
