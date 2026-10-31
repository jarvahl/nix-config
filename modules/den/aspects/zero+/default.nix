{
  den,
  lib,
  recovery,
  ...
}:
let
  host = "zero";
in
lib.mkMerge [
  {
    den = {
      aspects.${host} = {
        includes =
          (with den.aspects.sops; [
            # secrets
            (secret
              {
                group = "root";
                name = "ssh/host_key";
                owner = "root";
                path = "/etc/ssh/ssh_host_ed25519_key";
                restartUnits = [ "sshd.service" ];
              }
              {
                nixos = { path, ... }: {
                  services.openssh.hostKeys = [
                    {
                      inherit path;
                      type = "ed25519";
                    }
                  ];
                };
              }
            )
            (secret
              {
                name = "tailscale/auth_key";
                path = "/run/secrets/tailscale/auth_key";
                restartUnits = [
                  "tailscaled-logout.service"
                  "tailscaled-autoconnect.service"
                ];
              }
              {
                nixos = { path, ... }: {
                  services.tailscale.authKeyFile = path;
                };
              }
            )
          ])
          ++ (with den.aspects; [
            # system
            comma
            fonts
            podman
            ssh
            tailscale
          ]);

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

            # Keep zero running with the lid closed while connected to external power.
            services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

            swapDevices = [
              { device = "/dev/disk/by-uuid/ef842ad0-2a1b-4e24-a71b-61bb49cc4c55"; }
            ];
          };
      };

      hosts.x86_64-linux.${host}.secrets.file = ./host.sops.yaml;
    };

    sopsFile = {
      creation_rules = recovery [
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

  (
    let
      user = "jarvahl";
    in
    {
      den = {
        aspects."${user}@${host}" = {
          hjem.files.".ssh/config.d/dvalin".text = ''
            Host dvalin
              HostName dvalin.tailbf412b.ts.net
              User assistant
              IdentityFile ~/.ssh/keys.d/dvalin
              IdentitiesOnly yes
          '';

          includes =
            (with den.aspects; [
              # ui
              foot
              (hyperland hyperland.autologin)
              hypridle
              linger
              quickshell
              swaybg
            ])
            ++ (with den.aspects; [
              # tools
              clipboard
              console
              development
              herdr
              pi
            ])
            ++ (with den.aspects; [
              # accounts
              github
            ])
            ++ (with den.aspects.sops; [
              (secret
                {
                  mode = "0600";
                  name = "ssh/dvalin";
                  path = ".ssh/keys.d/dvalin";
                }
                {
                  hjem = { };
                }
              )
            ])
            ++ (with den.batteries; [
              # batteries
              (user-shell "zsh")
            ]);

          provides.to-hosts =
            with den.aspects.sops;
            secret
              {
                mode = "0400";
                name = "users/${user}/hashed_password";
              }
              {
                nixos = { lib, path, ... }: {
                  sops.secrets."users/${user}/hashed_password".neededForUsers = true;
                  users.users.${user} = {
                    hashedPasswordFile = path;
                    initialPassword = lib.mkForce null;
                  };
                };
              };
        };

        hosts.x86_64-linux.${host}.users.${user} = {
          classes = [ "hjem" ];
          secrets.file = ./user-${user}.sops.yaml;
        };
      };

      sopsFile = {
        creation_rules = recovery [
          {
            key_groups = [
              { age = [ "${user}@${host}" ]; }
            ];
            path_regex = ./user-${user}.sops.yaml;
          }
        ];

        keys."${user}@${host}" = "age1gfhnnsfzf839uvyr3nf6r3cl85zk4hvewkjpfpncxe8y7dxraeeqyr4y82";
      };
    }
  )
]
