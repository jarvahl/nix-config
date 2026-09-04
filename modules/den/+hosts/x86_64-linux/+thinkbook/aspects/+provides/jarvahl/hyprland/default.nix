{ ... }:
{
  den.aspects.thinkbook = {
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
          files = lib.mapAttrs' hyprlandFile hyprlandFiles;
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
