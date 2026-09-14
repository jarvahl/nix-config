{ lib, ... }:
{
  den.aspects.apex.nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.adwaita-icon-theme ];

    programs.dconf.profiles.user.databases = [
      {
        locks = [
          "/org/gnome/desktop/interface/cursor-size"
          "/org/gnome/desktop/interface/cursor-theme"
          "/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type"
        ];
        settings."org/gnome/desktop/interface" = {
          cursor-size = lib.gvariant.mkInt32 24;
          cursor-theme = "Adwaita";
        };
        settings."org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
        };
      }
    ];

    services.displayManager.gdm.enable = false;
    services.desktopManager.gnome.enable = true;
  };
}
