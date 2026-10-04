{ nixosSystem, self, ... }:

let
  inherit (self.lib) vm;

  host = "cargo";
in
{
  flake.nixosConfigurations.${host} = nixosSystem {
    modules = [
      self.nixosModules.${host}
    ];

    system = "x86_64-linux";
  };

  perSystem = { lib, pkgs, ... }: {
    apps.${host}.program = vm {
      inherit host lib pkgs;
    };
  };
}
