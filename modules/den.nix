{ den, inputs, ... }:
{
  imports = [
    inputs.den.flakeModule
  ];

  den.default = {
    includes = with den.batteries; [
      define-user
      hostname
      inputs'
      primary-user
      self'
    ];

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        jq
        python3
        wget
      ];
    };
  };

  flake-file.inputs.den.url = "github:denful/den";
}
