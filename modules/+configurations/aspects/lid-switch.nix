{ ... }:
{
  den.aspects.lid-switch.nixos = {
    services.logind.settings.Login = {
      # Keep the laptop running with the lid closed on external power.
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };
  };
}
