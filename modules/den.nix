{ den, inputs, ... }:
{
  imports = [
    inputs.den.flakeModule
  ];

  den.default.includes = with den.batteries; [
    define-user
    hostname
    inputs'
    primary-user
    self'
  ];

  flake-file.inputs.den.url = "github:denful/den";
}
