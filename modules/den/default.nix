{
  den,
  inputs,
  lib,
  ...
}:
{
  den.default = {
    includes =
      (with den.batteries; [
        define-user
        hostname
        inputs'
        primary-user
        self'
      ])
      ++ (with den.aspects; [
        nix
        sudo
        sops.hashedPassword
      ]);

    nixos = { pkgs, ... }: {
      system.stateVersion = lib.mkDefault "25.11";

      environment.systemPackages = with pkgs; [
        jq
        python3
        wget
      ];
    };
  };

  flake-file.inputs.den.url = "github:denful/den";

  imports = [
    inputs.den.flakeModule
  ];
}
