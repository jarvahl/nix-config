{ ... }:
{
  den.aspects.hypridle.hjem = { pkgs, ... }: {
    rum.programs.hypridle = {
      enable = true;
      settings.listener = [
        {
          timeout = 600;
          "on-timeout" = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          "on-resume" = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        }
      ];
    };

    systemd.services.hypridle = {
      description = "Hyprland idle manager";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wants = [ "wayland-session-waitenv.service" ];
      after = [ "wayland-session-waitenv.service" ];

      serviceConfig = {
        ExecStart = "${pkgs.hypridle}/bin/hypridle";
        Restart = "on-failure";
      };
    };
  };
}
