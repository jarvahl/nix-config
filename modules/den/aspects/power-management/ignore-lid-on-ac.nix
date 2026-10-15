{ ... }:
{
  den.aspects.power-management.ignore-lid-on-ac.nixos = {
    services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  };
}
