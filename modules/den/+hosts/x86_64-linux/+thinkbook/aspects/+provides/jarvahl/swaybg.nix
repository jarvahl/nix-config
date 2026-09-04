{ ... }:
{
  den.aspects.thinkbook = {
    provides.jarvahl = {
      hjem = { pkgs, ... }: {
        packages = [ pkgs.swaybg ];

        systemd.services.swaybg = {
          description = "Hyprland background";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wants = [ "wayland-session-waitenv.service" ];
          after = [ "wayland-session-waitenv.service" ];

          serviceConfig = {
            ExecStart = "${pkgs.swaybg}/bin/swaybg -c '#c8c0b4'";
            Restart = "on-failure";
          };
        };
      };
    };
  };
}
