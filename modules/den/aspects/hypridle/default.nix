{ ... }:
{
  den.aspects.hypridle.hjem = { pkgs, ... }: {
    rum.programs.hypridle = {
      enable = true;
      settings.listener = [
        {
          "on-resume" = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
          "on-timeout" = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          timeout = 600;
        }
      ];
    };

    systemd.services.hypridle = {
      after = [ "wayland-session-waitenv.service" ];
      description = "Hyprland idle manager";
      partOf = [ "graphical-session.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.hypridle}/bin/hypridle";
        Restart = "on-failure";
      };

      wantedBy = [ "graphical-session.target" ];
      wants = [ "wayland-session-waitenv.service" ];
    };
  };
}
