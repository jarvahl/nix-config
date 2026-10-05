{ ... }:
{
  den.aspects."dynamic-island" = {
    hjem =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        dynamicIslandConfig = builtins.path {
          name = "dynamic-island";
          path = ./.;
          filter = path: type: type == "directory" || lib.hasSuffix ".qml" path;
        };

        launcherToggle = pkgs.writeShellScriptBin "launcher-toggle" ''
          config="$HOME/.config/quickshell/dynamic-island/Host.qml"
          exec ${pkgs.quickshell}/bin/qs -p "$(${pkgs.coreutils}/bin/readlink -f "$config")" ipc --any-display call launcher toggle
        '';
      in
      {
        files.".config/quickshell/dynamic-island".source = dynamicIslandConfig;

        packages = [
          pkgs.brightnessctl
          pkgs.gtk3
          pkgs.quickshell
          launcherToggle
        ];

        systemd.services.quickshell-dynamic-island = {
          description = "Quickshell Dynamic Island";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wants = [ "wayland-session-waitenv.service" ];
          after = [ "wayland-session-waitenv.service" ];
          restartTriggers = [ config.files.".config/quickshell/dynamic-island".source ];

          serviceConfig = {
            Environment = "PATH=${
              lib.makeBinPath [
                pkgs.brightnessctl
                pkgs.gtk3
              ]
            }:/etc/profiles/per-user/jarvahl/bin:/run/current-system/sw/bin";
            ExecStart = "${pkgs.quickshell}/bin/qs -p ${config.files.".config/quickshell/dynamic-island".source}/Host.qml";
            Restart = "on-failure";
          };
        };
      };
  };
}
