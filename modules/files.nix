{ ... }:
{
  flake-file.inputs.files = {
    url = "github:mightyiam/files";
    flake = false;
  };

  perSystem = { ... }: {
    files.writer.app = true;
  };
}
