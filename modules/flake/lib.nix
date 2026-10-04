{ self, ... }:

{
  flake.lib.vm =
    { host
    , lib
    , pkgs
    }:
    let
      inherit (lib) getExe;
      inherit (pkgs) coreutils writeShellApplication;
      inherit (self.nixosConfigurations.${host}.config.system.build) vm;
    in
    getExe (writeShellApplication {
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
    });
}
