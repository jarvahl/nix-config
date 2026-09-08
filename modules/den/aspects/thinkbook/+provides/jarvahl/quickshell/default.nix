{ ... }:
{
  den.aspects.thinkbook = {
    provides.jarvahl.hjem = { config, lib, pkgs, ... }:
      let
        quickshellConfig = builtins.path {
          name = "quickshell-config";
          path = ./.;
          filter = path: type:
            type == "directory" || lib.hasSuffix ".qml" path;
        };
      in
      {
        files.".config/quickshell".source = quickshellConfig;

        packages = [
          pkgs.brightnessctl
          pkgs.quickshell
        ];

        systemd.services.quickshell = {
          description = "Quickshell OSD";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wants = [ "wayland-session-waitenv.service" ];
          after = [ "wayland-session-waitenv.service" ];
          restartTriggers = [ config.files.".config/quickshell".source ];

          serviceConfig = {
            Environment = "PATH=${lib.makeBinPath [ pkgs.brightnessctl ]}";
            ExecStart = "${pkgs.quickshell}/bin/qs -p ${config.files.".config/quickshell".source}/index.qml";
            Restart = "on-failure";
          };
        };
      };
  };
}
