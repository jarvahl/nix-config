{ ... }:
{
  den.aspects.swaybg.hjem = { pkgs, ... }: {
    packages = [ pkgs.swaybg ];

    systemd.services.swaybg = {
      after = [ "wayland-session-waitenv.service" ];
      description = "Hyprland background";
      partOf = [ "graphical-session.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -c '#c8c0b4'";
        Restart = "on-failure";
      };

      wantedBy = [ "graphical-session.target" ];
      wants = [ "wayland-session-waitenv.service" ];
    };
  };
}
