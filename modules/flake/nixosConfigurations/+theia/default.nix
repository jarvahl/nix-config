{ nixosSystem, self, ... }:

let
  host = "theia";
in
{
  flake.nixosConfigurations.${host} = nixosSystem {
    modules = with self.nixosModules; [
      theia
    ];

    system = "x86_64-linux";
  };

  perSystem = { lib, pkgs, ... }:
    let
      inherit (lib) getExe;
      inherit (pkgs) coreutils writeShellApplication;
      inherit (self.nixosConfigurations.${host}.config.system.build) vm;
    in
    {
      apps.${host}.program =
        let
          runner = writeShellApplication {
            name = host;
            runtimeInputs = [
              coreutils
              vm
            ];
            text = ''
              workdir="$(mktemp -d)"
              trap 'rm -rf "$workdir"' EXIT
              cd "$workdir"
              exec run-${host}-vm
            '';
          };
        in
        getExe runner;
    };

  systems = [ "x86_64-linux" ];
}
