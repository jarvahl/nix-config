{ ... }:
{
  den.aspects.nix.nixos = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];

    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];

    programs.nix-ld.enable = true;
  };
}
