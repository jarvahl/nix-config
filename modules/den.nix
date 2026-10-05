{ inputs, ... }:
{
  imports = [
    inputs.den.flakeModule
  ];

  flake-file.inputs.den.url = "github:denful/den";
}
