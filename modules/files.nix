{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    files.url = "github:mightyiam/files";
    sops-file.url = "github:jarvahl/sops-file";
  };

  imports = [
    "${inputs.files.outPath}/flake-module.nix"
    inputs.sops-file.flakeModules.default
  ];

  perSystem = { config, pkgs, ... }: {
    apps.write-files = {
      program = lib.mkForce (
        lib.getExe (
          pkgs.writeShellApplication {
            name = "write-files";
            runtimeInputs = [ pkgs.gitMinimal ];
            text = ''
              cd "$(git rev-parse --show-toplevel)"
              ${lib.getExe config.packages.write-flake}
              exec ${lib.getExe config.files.writer.drv}
            '';
          }
        )
      );
      type = "app";
    };
  };
}
