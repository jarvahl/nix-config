{ den, inputs, lib, ... }:
lib.mkMerge [
  {
    den.aspects.io = {
      includes = with den.aspects; [
        ssh
        tailscale
      ];

      nixos = { config, ... }: {
        imports = [
          inputs.disko.nixosModules.disko
          ./_hardware-configuration.nix
        ];

        networking.hostName = "io";
        networking.networkmanager.enable = true;
        boot.kernelParams = [ "nomodeset" ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        disko.devices.disk.main = {
          type = "disk";
          device = "/dev/sda";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };

              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };

        sops.secrets."tailscale/authKey" = { };
        services.tailscale.authKeyFile = config.sops.secrets."tailscale/authKey".path;

        users.users.nixos = {
          initialPassword = "nix";
          extraGroups = [ "wheel" "networkmanager" ];
        };
      };
    };
  }
]
