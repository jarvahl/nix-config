{
  den,
  lib,
  recovery,
  ...
}:
let
  host = "dvalin";
in
lib.mkMerge [
  {
    den = {
      aspects.${host} = {
        includes =
          (with den.aspects.sops; [
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
          ])
          ++ (with den.aspects; [
            matrix
            ssh
            tailscale
            (tailscale.tags [ "services" ])
          ]);

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

      keys.${host} = "age1dtpml670fkfe63gnrc5qn29aye00h3al2yhrte88m9q58rszsatqjpxskz";
    };
  }
  (
    let
      user = "jarvahl";
    in
    {
      den = {
        aspects."${user}@${host}" = {
          includes =
            (with den.aspects; [
              console
              development
              linger
            ])
            ++ (with den.aspects.sops; [
              (secret { name = "gaia/matrix/password"; } { hjem = { }; })
              (secret { name = "gaia/matrix/user_id"; } { hjem = { }; })
              (secret {
                name = "matrix/password";
              } { hjem = { }; })
              (secret { name = "matrix/user_id"; } { hjem = { }; })
              (template
                {
                  content = secrets: ''
                    MATRIX_PASSWORD="${secrets."gaia/matrix/password"}"
                    MATRIX_USER_ID="${secrets."gaia/matrix/user_id"}"
                  '';
                  mode = "0400";
                  name = "gaia-matrix-environment";
                }
                {
                  hjem = { path, ... }: {
                    systemd.services.gaia.serviceConfig.EnvironmentFile = path;
                  };
                }
              )
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
                    openssh.authorizedKeys.keys = [
                      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBmMnmmkTSEsCQNf5C24GEhdO8vziNCMxqagUCD/eXN zero-to-dvalin"
                    ];
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

        keys."${user}@${host}" = "age15ny8fkpgznutmkze50rcvceq400r6nq68n2vpdsq3muuq6vcwqmqlspkng";
      };
    }
  )
  {
    den.hosts.x86_64-linux.${host}.users.nixos = {
      classes = [ "hjem" ];
      secrets.file = ./user-nixos.sops.yaml;
    };

    sopsFile = {
      creation_rules = recovery [
        {
          key_groups = [
            { age = [ "nixos@${host}" ]; }
          ];
          path_regex = ./user-nixos.sops.yaml;
        }
      ];

      keys."nixos@${host}" = "age1uj0ultfy0sxxty4jrczl7ajwwg42tefqqpzjedl246eghy7yjdjqfp6ysz";
    };
  }
]
