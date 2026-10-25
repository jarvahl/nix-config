{ inputs, lib, ... }:
{
  flake-file.inputs.files = {
    flake = false;
    url = "github:mightyiam/files";
  };

  imports = [ "${inputs.files}/flake-module.nix" ];

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

  readme-file.sections = lib.mkOrder 250 [
    {
      title = "Generated files";
      text = ''
        Run from this repository:

        ```sh
        nix run .#write-files
        ```

        This runs `write-flake` first (including lock updates and automatic
        follows), then writes the configured files, including documentation,
        agent instructions, skills, and GitHub workflows. Edit their Nix
        declarations, not the generated files.

        `nix run .#write-flake` only regenerates the flake and updates its lock.
        After input changes, run `write-files` again so the remaining generators
        use the updated inputs; each invocation uses its initial evaluation.
        Stage new source files before evaluation and new generated files before
        running `nix flake check`.
      '';
    }
  ];
}
