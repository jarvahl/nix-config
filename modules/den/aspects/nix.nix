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

    services.harmonia.gc = {
      automatic = true;
      dates = "daily";
      deleteOlderThan = "30d";
      enable = true;
      ensureFree = "20%";
      keepRecent = "2d";
      randomizedDelaySec = "1h";
      persistent = true;
    };
  };
}
