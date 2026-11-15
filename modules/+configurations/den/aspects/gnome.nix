{ ... }:
{
  den.aspects.gnome.nixos = {
    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;
  };
}
