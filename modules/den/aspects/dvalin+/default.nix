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
            (from ./secrets-host.yaml)
            (keyFile "/var/lib/sops-nix/key.txt")
            (secret rec {
              includes = [
                {
                  nixos = { ... }: {
                    services.tailscale.authKeyFile = path;
                  };
                }
              ];
              name = "tailscale/auth_key";
              path = "/run/secrets/tailscale/auth_key";
              restartUnits = [
                "tailscaled-logout.service"
                "tailscaled-autoconnect.service"
              ];
            })
            (secret rec {
              group = "root";
              includes = [
                {
                  nixos = { ... }: {
                    services.openssh.hostKeys = [
                      {
                        inherit path;
                        type = "ed25519";
                      }
                    ];
                  };
                }
              ];
              name = "ssh/host_key";
              owner = "root";
              path = "/etc/ssh/ssh_host_ed25519_key";
              restartUnits = [ "sshd.service" ];
            })
          ])
          ++ (with den.aspects; [
            ssh
            tailscale
          ])
          ++ (with den.aspects.tailscale; [
            (service {
              comment = "OpenClaw gateway";
              name = "openclaw";
              port = 18789;
              servicePort = 443;
            })
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

    sopsFile = {
      creation_rules = recovery [
        {
          key_groups = [
            { age = [ host ]; }
          ];
          path_regex = ./secrets-host.yaml;
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
          includes = with den.aspects.sops; [
            (from ./secrets-user-${user}.yaml)
            (keyFile ".config/sops/age/key.txt")
          ];
        };

        hosts.x86_64-linux.${host}.users.${user}.classes = [
          "hjem"
        ];
      };

      sopsFile = {
        creation_rules = recovery [
          {
            key_groups = [
              { age = [ "${user}@${host}" ]; }
            ];
            path_regex = ./secrets-user-${user}.yaml;
          }
        ];

        keys."${user}@${host}" = "age1ahknfhq9muvqrss3jgpwssa8af2wuuez4k8nn9g552y9hcyj63rqstkm58";
      };
    }
  )
]
