{ lib, ... }:
{
  den.aspects.gnome.nixos = {
    programs.dconf.profiles.gdm.databases = lib.mkBefore [
      {
        settings."org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-timeout = lib.gvariant.mkInt32 0;
          sleep-inactive-ac-type = "nothing";
        };
      }
    ];

    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;
  };
}
