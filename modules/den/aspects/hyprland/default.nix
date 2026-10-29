{ den, inputs, ... }:
with den.lib;
{
  den.aspects.hyperland = callable {
    hjem =
      { lib, pkgs, ... }:
      let
        toLua = lib.generators.toLua { };
        workspaces = map toString (lib.range 1 9);
      in
      {
        wayland.windowManager.hyprland = {
          configType = "lua";
          enable = true;
          package = null;
          portalPackage = null;

          settings = {
            bind =
              with lib.generators;
              [
                {
                  _args = [
                    "SUPER + B"
                    (mkLuaInline ''hl.dsp.exec_cmd("${pkgs.firefox}/bin/firefox")'')
                  ];
                }
                {
                  _args = [
                    "SUPER + C"
                    (mkLuaInline "hl.dsp.window.close()")
                  ];
                }
                {
                  _args = [
                    "SUPER + M"
                    (mkLuaInline "hl.dsp.exit()")
                  ];
                }
                {
                  _args = [
                    "SUPER + SHIFT + F11"
                    (mkLuaInline ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
                  ];
                }
                {
                  _args = [
                    "SUPER + SHIFT + F11"
                    (mkLuaInline ''hl.dsp.submap("focus-mode")'')
                  ];
                }
              ]
              ++ lib.concatMap (workspace: [
                {
                  _args = [
                    "SUPER + ${workspace}"
                    (mkLuaInline "hl.dsp.focus({ workspace = ${workspace} })")
                  ];
                }
                {
                  _args = [
                    "SUPER + SHIFT + ${workspace}"
                    (mkLuaInline "hl.dsp.window.move({ workspace = ${workspace} })")
                  ];
                }
              ]) workspaces
              ++
                lib.mapAttrsToList
                  (key: command: {
                    _args = [
                      key
                      (mkLuaInline "hl.dsp.exec_cmd(${toLua command})")
                      {
                        locked = true;
                        repeating = true;
                      }
                    ];
                  })
                  {
                    XF86AudioLowerVolume = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                    XF86AudioMicMute = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                    XF86AudioMute = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                    XF86AudioRaiseVolume = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
                    XF86MonBrightnessDown = "${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%-";
                    XF86MonBrightnessUp = "${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%+";
                  };

            config = {
              decoration = {
                rounding = 14;
                shadow = {
                  color = "0xaa000000";
                  range = 18;
                };
              };

              general = {
                border_size = 0;
                gaps_in = 8;
                gaps_out = {
                  bottom = 48;
                  left = 45;
                  right = 45;
                  top = 0;
                };
              };

              misc = {
                background_color = "0xc8c0b4";
                disable_hyprland_logo = true;
                disable_splash_rendering = true;
                force_default_wallpaper = 0;
              };
            };

            monitor = {
              mode = "preferred";
              output = "";
              position = "auto";
              scale = 1.0;
            };

            on._args = [
              "hyprland.start"
              (lib.generators.mkLuaInline ''function() hl.exec_cmd("${pkgs.uwsm}/bin/uwsm finalize") end'')
            ];
          };

          submaps.focus-mode.settings.bind = with lib.generators; [
            {
              _args = [
                "SUPER + Escape"
                (mkLuaInline "hl.dsp.window.fullscreen()")
              ];
            }
            {
              _args = [
                "SUPER + Escape"
                (mkLuaInline ''hl.dsp.submap("reset")'')
              ];
            }
          ];

          systemd.enable = false;
        };
      };

    nixos = { pkgs, ... }: {
      hjem.extraModules = [
        (inputs.home-manager + "/modules/services/window-managers/hyprland")
        (inputs.home-manager + "/modules/misc/xdg/portal.nix")
        ({ lib, ... }: {
          imports = [
            (lib.mkAliasOptionModule
              [ "systemd" "user" "sessionVariables" ]
              [ "environment" "sessionVariables" ]
            )
          ];

          options.xdg.configFile = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options.onChange = lib.mkOption {
                  default = "";
                  type = lib.types.enum [ "" ];
                };
              }
            );
          };
        })
      ];

      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      services.udev.packages = [ pkgs.brightnessctl ];
    };

    user.extraGroups = [ "video" ];
  };
}
