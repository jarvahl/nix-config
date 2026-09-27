{ den
, lib
, ...
}:
lib.mkMerge [
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

      includes = with den.aspects; [
        tailscale
        ssh
        podman
        fonts
      ];
    };
  }

  {
    den.aspects.apex.nixos = { pkgs, ... }: {
      virtualisation.libvirtd.enable = true;
      virtualisation.libvirtd.qemu.runAsRoot = true;
      users.users.jarvahl.extraGroups = [ "libvirtd" ];
      environment.systemPackages = with pkgs; [
        virt-manager
        qemu_kvm
      ];
    };
  }

  {
    den.aspects.apex.nixos = { pkgs, ... }: {
      services.atd.enable = true;
      environment.systemPackages = [ pkgs.at ];
    };
  }

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

  {
    den.aspects.apex.nixos = { pkgs, ... }: {
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
    den.aspects.apex.nixos = { pkgs, ... }: {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cpu;
        environmentVariables = {
          OLLAMA_KV_CACHE_TYPE = "q8_0";
          OLLAMA_NUM_PARALLEL = "1";
          OLLAMA_MAX_QUEUE = "2";
        };
      };
    };
  }

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
    };
  }
]
