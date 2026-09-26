{ den
, inputs
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
      imports = [
        inputs.hermes-agent.nixosModules.default
        inputs.hermes-webui.nixosModules.default
      ];

      users.groups.hermes.gid = 973;
      users.users.hermes = {
        uid = 982;
        group = "hermes";
        isSystemUser = true;
        home = "/var/lib/hermes";
        createHome = true;
      };

      services.hermes-agent.enable = true;

      services.hermes-webui = {
        enable = true;
        host = "127.0.0.1";
        port = 8787;
        user = "hermes";
        group = "hermes";
        hermesHome = "/var/lib/hermes/.hermes";
        agent.package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      systemd.services.hermes-webui-tailscale-serve = {
        description = "Expose Hermes WebUI through Tailscale HTTPS";
        after = [
          "tailscaled.service"
          "hermes-webui.service"
        ];
        wants = [
          "tailscaled.service"
          "hermes-webui.service"
        ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.tailscale ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          tailscale serve --yes --bg --https=443 127.0.0.1:8787
        '';
      };
    };

    flake-file.inputs = {
      hermes-agent.url = "github:NousResearch/hermes-agent";
      hermes-webui = {
        url = "github:nesquena/hermes-webui";
        inputs.nixpkgs.follows = "nixpkgs";
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
