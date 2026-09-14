{ den, ... }:
{
  den.aspects.apex = {
    nixos = { pkgs, ... }: {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        gamescopeSession.enable = true;
        protontricks.enable = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
        extraPackages = with pkgs; [ mangohud ];
      };

      programs.gamemode.enable = true;
      programs.gamescope.enable = true;

      environment.systemPackages = with pkgs; [ mangohud protonup-qt ];
    };

    includes = [
      (den.batteries.unfree [
        "steam"
        "steam-original"
        "steam-run"
        "steam-unwrapped"
      ])
    ];
  };
}
