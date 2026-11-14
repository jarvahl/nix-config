let
  host = "zero";
in
{ den, lib, ... }:

lib.mkMerge [
  {
    den = {
      aspects.${host} = {
        includes = (
          with den.aspects;
          [
            # system
            comma
            fonts
            podman
            ssh
            tailscale
          ]
        );

        nixos =
          {
            config,
            lib,
            modulesPath,
            pkgs,
            ...
          }:
          {
            boot.extraModulePackages = [ ];
            boot.initrd.availableKernelModules = [
              "xhci_pci"
              "thunderbolt"
              "nvme"
              "usb_storage"
              "sd_mod"
              "sdhci_pci"
            ];
            boot.initrd.kernelModules = [ ];
            boot.kernelModules = [ "kvm-intel" ];
            boot.loader.efi.canTouchEfiVariables = true;
            boot.loader.systemd-boot.enable = true;

            fileSystems."/" = {
              device = "/dev/disk/by-uuid/264e6d66-3283-4c17-a589-caf6e6ca0f19";
              fsType = "ext4";
            };

            fileSystems."/boot" = {
              device = "/dev/disk/by-uuid/546D-4F36";
              fsType = "vfat";
              options = [
                "fmask=0077"
                "dmask=0077"
              ];
            };

            hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

            imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

            networking.networkmanager.enable = true;
            networking.useDHCP = lib.mkDefault true;

            environment.systemPackages = [ pkgs.networkmanager ];

            swapDevices = [
              { device = "/dev/disk/by-uuid/ef842ad0-2a1b-4e24-a71b-61bb49cc4c55"; }
            ];
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

      keys.${host} = "age1wxm2g87tj35cthkl02lx3jzefkkfxkpr4kseyrzpuwhwkpfwm34smhjuuz";
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
          hjem.files.".ssh/config.d/dvalin".text = ''
            Host dvalin
              HostName dvalin.tailbf412b.ts.net
              User jarvahl
              IdentityFile ~/.ssh/id_ed25519
              IdentitiesOnly yes
          '';

          includes =
            (with den.aspects; [
              # ui
              foot
              linger
            ])
            ++ (with den.aspects; [
              # tools
              clipboard
              console
              development
              herdr
              (pi {
                extensions =
                  { self', ... }:
                  with self'.packages;
                  [
                    "${pi-diff-review}/pi-diff-review/index.ts"
                    "${pi-prompt-timer}/pi-prompt-timer/index.ts"
                    "${pi-ponytail}/pi-ponytail/index.js"
                  ];
              })
            ])
            ++ (with den.aspects; [
              # accounts
              certificates
              gh
            ])
            ++ (with den.batteries; [
              # batteries
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

          keys."${user}@${host}" = "age1gfhnnsfzf839uvyr3nf6r3cl85zk4hvewkjpfpncxe8y7dxraeeqyr4y82";
        };
      }
    ]
  )
]
