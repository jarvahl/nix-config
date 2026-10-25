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
            (from ./host.sops.yaml)
            (keyFile "/var/lib/sops-nix/key.txt")
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
                nixos = { config, ... }: {
                  services.tailscale.authKeyFile = config.sops.secrets."tailscale/auth_key".path;
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
                nixos = { config, ... }: {
                  services.openssh.hostKeys = [
                    {
                      path = config.sops.secrets."ssh/host_key".path;
                      type = "ed25519";
                    }
                  ];
                };
              }
            )
          ])
          ++ (with den.aspects; [
            ssh
            tailscale
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
              (openclaw {
                includes =
                  (with tailscale; [
                    (service {
                      comment = "OpenClaw gateway";
                      name = "openclaw";
                      port = 18789;
                      servicePort = 443;
                    })
                  ])
                  ++ (with sops; [
                    (secret {
                      name = "openclaw/gateway_token";
                      path = ".config/openclaw/gateway-token";
                    } { })
                  ]);
              })
            ])
            ++ (with den.aspects.sops; [
              (from ./user-${user}.sops.yaml)
              (keyFile ".config/sops/age/key.txt")
            ]);
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
            path_regex = ./user-${user}.sops.yaml;
          }
        ];

        keys."${user}@${host}" = "age1ahknfhq9muvqrss3jgpwssa8af2wuuez4k8nn9g552y9hcyj63rqstkm58";
      };
    }
  )
]
