{ den, lib, ... }:
let
  host = "zero";
in
lib.mkMerge [
  {
    den = {
      aspects.${host} = {
        includes = with den.aspects; [
          (sops.file ./secrets.yaml)
          ssh
          (ssh.host-key {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          })
          tailscale
        ];

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

    "sops-file" = {
      creation_rules = [
        {
          key_groups = [
            { age = [ host ]; }
          ];
          path_regex = ./secrets.yaml;
        }
      ];

      keys.${host} = "age1y8xgchal8k9gu2hgl4jde53ap0rxj4p3kfs3a0xt2c5cmx3ztexs96dm04";
    };
  }

  (
    let
      user = "jarvahl";
    in
    {
      den = {
        aspects."${user}@${host}".includes =
          (with den.aspects; [
            # UI
            foot
            hyperland
            hyperland.autologin
            hypridle
            quickshell
            swaybg

            # Console
            pi
            zsh
          ])
          ++ (with den.batteries; [
            (user-shell "zsh")
          ]);

        hosts.x86_64-linux.${host}.users.${user}.classes = [ "hjem" ];
      };
    }
  )
]
