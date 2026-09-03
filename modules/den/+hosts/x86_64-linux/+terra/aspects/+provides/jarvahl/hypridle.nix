{ ... }:
{
  den.aspects.terra = {
    provides.jarvahl.hjem = { config, pkgs, ... }: {
      packages = [ pkgs.hypridle ];

      files.".config/hypr/hypridle.conf".source = pkgs.writeText "hypridle.conf" ''
        listener {
          timeout = 600
          on-timeout = ${pkgs.hyprland}/bin/hyprctl dispatch dpms off
          on-resume = ${pkgs.hyprland}/bin/hyprctl dispatch dpms on
        }
      '';

      systemd.services.hypridle = {
        description = "Hyprland idle manager";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wants = [ "wayland-session-waitenv.service" ];
        after = [ "wayland-session-waitenv.service" ];
        restartTriggers = [ config.files.".config/hypr/hypridle.conf".source ];

        serviceConfig = {
          ExecStart = "${pkgs.hypridle}/bin/hypridle -c ${config.files.".config/hypr/hypridle.conf".source}";
          Restart = "on-failure";
        };
      };
    };
  };
}
