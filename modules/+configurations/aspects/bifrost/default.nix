{ den, lib, ... }:
let
  host = "bifrost";
in
lib.mkMerge [
  {
    den = {
      aspects.${host} = {
        includes = (
          with den.aspects;
          [
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

            users.users.agent = {
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
          path_regex = ./secrets.sops.yaml;
        }
      ];

      keys.${host} = "age1dtpml670fkfe63gnrc5qn29aye00h3al2yhrte88m9q58rszsatqjpxskz";
    };
  }

  {
    den.aspects.${host}.nixos = {
      sops.age.keyFile = "/var/lib/sops-outputs/key.txt";
      sops.defaultSopsFile = ./secrets.sops.yaml;
    };
  }
]
