{ den, inputs, ... }:
{
  imports = [
    inputs.den.flakeModule
  ];

  den.default.includes = with den.batteries; [
    define-user
    hostname
    primary-user
  ];

  flake-file.inputs.den.url = "github:denful/den";
}
