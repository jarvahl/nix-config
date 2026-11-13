let
  host = "dvalin";
in
{ den, lib, ... }:

lib.mkMerge [
  {
    den = {
      aspects.${host} = {
        includes = (
          with den.aspects;
          [
            matrix
            ssh
            tailscale
            (tailscale.tags [ "services" ])
          ]
        );

        nixos =
          {
            config,
            lib,
            modulesPath,
            ...
          }:
          {
            boot.initrd.availableKernelModules = [
              "xhci_pci"
              "ahci"
              "ehci_pci"
              "usbhid"
              "usb_storage"
              "sd_mod"
            ];
            boot.initrd.kernelModules = [ ];
            boot.kernelModules = [ ];
            boot.extraModulePackages = [ ];
            boot.kernelParams = [ "nomodeset" ];
            boot.loader.efi.canTouchEfiVariables = true;
            boot.loader.systemd-boot.enable = true;

            fileSystems."/" = {
              device = "/dev/disk/by-partlabel/disk-main-root";
              fsType = "ext4";
              options = [ "x-initrd.mount" ];
            };

            fileSystems."/boot" = {
              device = "/dev/disk/by-partlabel/disk-main-ESP";
              fsType = "vfat";
              options = [ "umask=0077" ];
            };

            hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

            imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

            networking.networkmanager.enable = true;

            services.tailscale.services.openclaw = {
              comment = "OpenClaw gateway";
              port = 18789;
            };

            users.users.nixos = {
              extraGroups = [
                "wheel"
                "networkmanager"
              ];
              group = "users";
              initialPassword = "nix";
              isNormalUser = true;
            };
          };
      };

      hosts.x86_64-linux.${host} = { };
    };

    sops.file = {
      creation_rules = [
        {
          key_groups = [
            { age = [ host ]; }
          ];
          path_regex = ./host.sops.yaml;
        }
      ];

      keys.${host} = "age1dtpml670fkfe63gnrc5qn29aye00h3al2yhrte88m9q58rszsatqjpxskz";
    };
  }

  {
    den.aspects.${host}.sops.nixos = {
      sops.age.keyFile = "/var/lib/sops-outputs/key.txt";
      sops.defaultSopsFile = ./host.sops.yaml;
    };
  }
  (
    let
      user = "jarvahl";
      secretsFile = ./user-${user}.sops.yaml;
    in
    lib.mkMerge [
      {
        den.aspects."${user}@${host}" = {
          includes =
            (with den.aspects; [
              certificates
              console
              development
              gh
              linger
            ])
            ++ (with den.batteries; [
              (user-shell "zsh")
            ]);
        };
      }
      {
        den.aspects."${user}@${host}".sops = {
          hjem = {
            sops.age.keyFile = ".config/sops/age/key.txt";
            sops.defaultSopsFile = secretsFile;
          };

          provides.to-hosts.nixos =
            { config, ... }:
            {
              sops.secrets."${user}/age_key" = {
                group = "users";
                mode = "0600";
                owner = user;
                path = "${config.users.users.${user}.home}/.config/sops/age/key.txt";
                sopsFile = ./host.sops.yaml;
              };
            };
        };
      }
      {
        den.aspects."${user}@${host}".sops.nixos =
          { config, lib, ... }:
          {
            sops.secrets."${user}/hashed_password" = {
              mode = "0400";
              neededForUsers = true;
              sopsFile = ./host.sops.yaml;
            };

            users.users.${user} = {
              hashedPasswordFile = config.sops.secrets."${user}/hashed_password".path;
              initialPassword = lib.mkForce null;
            };
          };
      }
      {
        den.hosts.x86_64-linux.${host}.users.${user} = {
          classes = [ "hjem" ];
        };
      }
      {
        sops.file = {
          creation_rules = [
            {
              key_groups = [
                { age = [ "${user}@${host}" ]; }
              ];
              path_regex = secretsFile;
            }
          ];

          keys."${user}@${host}" = "age15ny8fkpgznutmkze50rcvceq400r6nq68n2vpdsq3muuq6vcwqmqlspkng";
        };
      }
    ]
  )
  (

    let
      host = "dvalin";
      user = "nixos";
      secretsFile = ./user-nixos.sops.yaml;
    in
    lib.mkMerge [
      {
        den.aspects."${user}@${host}" = { };
      }
      {
        den.aspects."${user}@${host}".sops = {
          hjem = {
            sops.age.keyFile = ".config/sops/age/key.txt";
            sops.defaultSopsFile = secretsFile;
          };

          provides.to-hosts.nixos =
            { config, ... }:
            {
              sops.secrets."${user}/age_key" = {
                group = "users";
                mode = "0600";
                owner = user;
                path = "${config.users.users.${user}.home}/.config/sops/age/key.txt";
                sopsFile = ./host.sops.yaml;
              };
            };
        };
      }
      {
        den.hosts.x86_64-linux.${host}.users.${user} = {
          classes = [ "hjem" ];
        };
      }
      {
        sops.file = {
          creation_rules = [
            {
              key_groups = [
                { age = [ "${user}@${host}" ]; }
              ];
              path_regex = secretsFile;
            }
          ];

          keys."${user}@${host}" = "age1uj0ultfy0sxxty4jrczl7ajwwg42tefqqpzjedl246eghy7yjdjqfp6ysz";
        };
      }
    ]
  )
]
