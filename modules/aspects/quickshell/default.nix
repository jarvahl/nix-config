{ ... }:
{
  den.aspects.quickshell = {
    hjem =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        quickshellConfig = builtins.path {
          filter = path: type: type == "directory" || lib.hasSuffix ".qml" path;
          name = "quickshell";
          path = ./.;
        };

        launcherToggle = pkgs.writeShellScriptBin "launcher-toggle" ''
          config="$HOME/.config/quickshell/dynamic-island/Host.qml"
          exec ${pkgs.quickshell}/bin/qs -p "$(${pkgs.coreutils}/bin/readlink -f "$config")" ipc --any-display call launcher toggle
        '';
      in
      {
        files.".config/quickshell/dynamic-island".source = quickshellConfig;

        packages = [
          pkgs.brightnessctl
          pkgs.gtk3
          pkgs.quickshell
          launcherToggle
        ];

        rum.desktops.hyprland.settings.bind = lib.mkIf config.rum.desktops.hyprland.enable [
          "SUPER, P, exec, launcher-toggle"
        ];

        systemd.services.quickshell-dynamic-island = {
          after = [ "wayland-session-waitenv.service" ];
          description = "Quickshell Dynamic Island";
          partOf = [ "graphical-session.target" ];
          restartTriggers = [ config.files.".config/quickshell/dynamic-island".source ];

          serviceConfig = {
            Environment = "PATH=${
              lib.makeBinPath [
                pkgs.brightnessctl
                pkgs.gtk3
              ]
            }:/etc/profiles/per-user/jarvahl/bin:/run/current-system/sw/bin";
            ExecStart = "${pkgs.quickshell}/bin/qs -p ${
              config.files.".config/quickshell/dynamic-island".source
            }/Host.qml";
            Restart = "on-failure";
          };

          wantedBy = [ "graphical-session.target" ];
          wants = [ "wayland-session-waitenv.service" ];
        };
      };
  };
}
