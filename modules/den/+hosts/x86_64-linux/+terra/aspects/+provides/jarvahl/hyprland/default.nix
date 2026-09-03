{ ... }:
{
  den.aspects.terra = {
    provides.jarvahl = {
      hjem = { lib, pkgs, ... }:
        let
          hyprlandFiles = lib.filterAttrs
            (name: type:
              type == "regular"
              && (lib.hasSuffix ".lua" name || lib.hasSuffix ".lua.nix" name))
            (builtins.readDir ./.);

          hyprlandFileName = name:
            lib.removePrefix "_"
              (if lib.hasSuffix ".lua.nix" name then lib.removeSuffix ".nix" name else name);

          hyprlandFile = name: _: {
            name = ".config/hypr/${hyprlandFileName name}";
            value.source =
              if lib.hasSuffix ".lua.nix" name
              then pkgs.writeText (hyprlandFileName name) (import ./${name} { inherit pkgs; })
              else ./${name};
          };
        in
        {
          files = lib.mapAttrs' hyprlandFile hyprlandFiles // {
            ".config/foot/foot.ini".text = ''
              [main]
              pad=16x16
              font=monospace:size=12
            '';
          };

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
