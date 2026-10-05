{ ... }:
{
  flake-file.inputs.files = {
    flake = false;
    url = "github:mightyiam/files";
  };

  perSystem = { ... }: {
    files.writer.app = true;
  };
}
