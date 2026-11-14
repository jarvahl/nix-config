{ ... }:
{
  den.aspects.zero.nixos = {
    services = {
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;

      # Keep zero running with the lid closed while connected to external power.
      logind.settings.Login = {
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitchExternalPower = "ignore";
      };
    };
  };
}
