{ ... }:
{
  den.aspects.terra = {
    provides.jarvahl = {
      hjem = { pkgs, ... }: {
        files.".config/hypr/hyprland.lua".source =
          pkgs.writeText "hyprland.lua" (import ./_hyprland.lua.nix { inherit pkgs; });

        files.".config/foot/foot.ini".text = ''
          [main]
          pad=16x16
          font=monospace:size=12
        '';

        packages = [
          pkgs.foot
          pkgs.swaybg
        ];

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

      nixos = { pkgs, ... }: {
        programs.hyprland = {
          enable = true;
          withUWSM = true;
        };

        services.udev.packages = [ pkgs.brightnessctl ];
      };

      user.extraGroups = [ "video" ];
    };
  };
}
