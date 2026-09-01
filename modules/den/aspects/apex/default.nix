{ den, lib, ... }:
{
  den.aspects.apex = lib.mkMerge [
    {
      nixos = {
        imports = [ ./_hardware-configuration.nix ];

        sops.defaultSopsFile = ./secrets.yml;

        networking.networkmanager.enable = true;

        services.upower.enable = true;
        services.power-profiles-daemon.enable = true;

        time.timeZone = "Europe/Warsaw";

        services.logind.settings.Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "ignore";
        };
      };

    }
    {
      nixos = { pkgs, ... }: {
        services.atd.enable = true;
        environment.systemPackages = [ pkgs.at ];
      };
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

        services.greetd = {
          enable = true;
          settings = rec {
            initial_session = {
              command = "${pkgs.uwsm}/bin/uwsm start -- hyprland-uwsm.desktop";
              user = "jarvahl";
            };

            default_session = initial_session;
          };
        };
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
          extraCompatPackages = with pkgs; [ proton-ge-bin ];
          extraPackages = with pkgs; [ mangohud ];
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
    {
      includes = with den.aspects; [
        tailscale
        ssh
        podman
        fonts
      ];
    }
  ];
}
