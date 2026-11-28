{ den, lib, ... }:
let
  host = "asgard";
in
lib.mkMerge [
  {
    den = {
      aspects.${host} = {
        includes = (
          with den.aspects;
          [
            # system
            comma
            firefox
            fonts
            lid-switch
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

            services.greetd = {
              enable = true;
              settings = rec {
                initial_session = {
                  command = "${lib.getExe pkgs.uwsm} start -- hyprland-uwsm.desktop";
                  user = "jarvahl";
                };

                default_session = initial_session;
              };
            };

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
          path_regex = ./secrets.sops.yaml;
        }
      ];

      keys.${host} = "age1wxm2g87tj35cthkl02lx3jzefkkfxkpr4kseyrzpuwhwkpfwm34smhjuuz";
    };
  }

  {
    den.aspects.${host}.nixos = {
      sops.age.keyFile = "/var/lib/sops-outputs/key.txt";
      sops.defaultSopsFile = ./secrets.sops.yaml;
    };
  }
]
