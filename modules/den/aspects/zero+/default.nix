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
          (with den.aspects; [
            comma
            fonts
            podman
            ssh
            tailscale
          ])
          ++ (with den.aspects.sops; [
            (from ./secrets-host.yaml)
            (keyFile "/var/lib/sops-nix/key.txt")
            (secret (
              let
                path = "/etc/ssh/ssh_host_ed25519_key";
              in
              {
                aspect.services.openssh.hostKeys = [
                  {
                    inherit path;
                    type = "ed25519";
                  }
                ];
                group = "root";
                name = "ssh/host_key";
                owner = "root";
                inherit path;
                restartUnits = [ "sshd.service" ];
              }
            ))
          ]);

        nixos =
          {
            config,
            lib,
            modulesPath,
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

            networking.useDHCP = lib.mkDefault true;

            swapDevices = [
              { device = "/dev/disk/by-uuid/ef842ad0-2a1b-4e24-a71b-61bb49cc4c55"; }
            ];
          };
      };

      hosts.x86_64-linux.${host} = { };
    };

    sops-file = {
      creation_rules = recovery [
        {
          key_groups = [
            { age = [ host ]; }
          ];
          path_regex = ./secrets-host.yaml;
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
          includes =
            (with den.aspects; [
              # UI
              foot
              (hyperland {
                includes = { autologin, ... }: [
                  autologin
                ];
              })
              hypridle
              quickshell
              swaybg

              # Console
              bat
              eza
              fzf
              nvim
              pi
              worktrunk
              zsh
            ])
            ++ (with den.aspects.sops; [
              (from ./secrets-user-${user}.yaml)
              (keyFile ".config/sops/age/key.txt")
            ])
            ++ (with den.batteries; [
              (user-shell "zsh")
            ]);

        };

        hosts.x86_64-linux.${host}.users.${user}.classes = [
          "hjem"
        ];
      };

      sops-file = {
        creation_rules = recovery [
          {
            key_groups = [
              { age = [ "${user}@${host}" ]; }
            ];
            path_regex = ./secrets-user-${user}.yaml;
          }
        ];

        keys."${user}@${host}" = "age1gfhnnsfzf839uvyr3nf6r3cl85zk4hvewkjpfpncxe8y7dxraeeqyr4y82";
      };
    }
  )
]
