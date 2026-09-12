{ den, ... }:
{
  den.aspects.apex = {
    nixos = {
      imports = [ ./_hardware-configuration.nix ];
      networking.networkmanager.enable = true;
      services.upower.enable = true;
      services.power-profiles-daemon.enable = true;
      time.timeZone = "Europe/Warsaw";

      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "ignore";
      };
    };

    includes = with den.aspects; [ tailscale ssh podman fonts ];
  };
}
