{ den, lib, ... }:
{
  den.aspects.terra = lib.mkMerge [
    {
      nixos = {
        sops.defaultSopsFile = ./secrets.yml;

        networking.networkmanager.enable = true;

        services.atd.enable = true;
        services.upower.enable = true;
        services.power-profiles-daemon.enable = true;

        time.timeZone = "Europe/Warsaw";

        services.logind.settings.Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "ignore";
        };
      };

      includes =
        (with den.aspects; [ tailscale ssh podman fonts ])
        ++ [ (den.batteries.import-tree ./aspects/_modules) ];
    }
    {
      nixos = { pkgs, ... }: {
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

        services.getty = {
          autologinUser = "jarvahl";
          autologinOnce = true;
        };

        environment.loginShellInit = lib.mkAfter ''
          if [ "''${USER-}" = jarvahl ] \
            && [ "''${XDG_VTNR-}" = 1 ] \
            && [ "$(tty 2>/dev/null)" = /dev/tty1 ] \
            && [ -n "''${XDG_SESSION_ID-}" ] \
            && [ "$(loginctl show-session "$XDG_SESSION_ID" -p Active --value 2>/dev/null)" = yes ] \
            && [ "$(loginctl show-session "$XDG_SESSION_ID" -p Remote --value 2>/dev/null)" = no ]; then
            exec uwsm start hyprland-uwsm.desktop
          fi
        '';
      };
    }
    {
      nixos = { pkgs, ... }: {
        programs.steam = {
          enable = true;
          remotePlay.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
          gamescopeSession.enable = true;
          protontricks.enable = true;
          extraCompatPackages = with pkgs; [
            proton-ge-bin
          ];
          extraPackages = with pkgs; [
            mangohud
          ];
        };

        programs.gamemode.enable = true;
        programs.gamescope.enable = true;

        environment.systemPackages = with pkgs; [
          mangohud
          protonup-qt
        ];
      };

      includes = [
        (den.batteries.unfree [
          "steam"
          "steam-original"
          "steam-run"
          "steam-unwrapped"
        ])
      ];
    }
  ];

  den.hosts.x86_64-linux.terra = {
    users.jarvahl = { };
    nixosContainers = [ den.hosts.x86_64-linux.titan ];
  };
}
