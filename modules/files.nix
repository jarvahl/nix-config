{ inputs, ... }:
{
  flake-file.inputs.files = {
    flake = false;
    url = "github:mightyiam/files";
  };

  imports = [ "${inputs.files}/flake-module.nix" ];

  perSystem = { ... }: {
    files.writer.app = true;
  };
}
