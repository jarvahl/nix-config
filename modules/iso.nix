{ inputs, ... }:
{
  flake.nixosConfigurations.ssh-installer = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      ({ pkgs, ... }: {
        networking = {
          hostName = "ssh-installer";
          networkmanager.enable = true;
        };

        boot.kernelModules = [ "rtl8xxxu" ];
        hardware.enableRedistributableFirmware = true;

        networking.networkmanager.ensureProfiles = {
          environmentFiles = [ "/etc/NetworkManager/installer-wifi.env" ];
          profiles.installer-ethernet = {
            connection = {
              id = "installer-ethernet";
              type = "ethernet";
              autoconnect = true;
              autoconnect-priority = 100;
            };
            ipv4.method = "auto";
            ipv6.method = "auto";
          };

          profiles.installer-wifi = {
            connection = {
              id = "installer-wifi";
              type = "wifi";
              autoconnect = true;
              autoconnect-priority = 100;
            };
            wifi = {
              mode = "infrastructure";
              ssid = "$WIFI_SSID";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WIFI_PSK";
            };
            ipv4.method = "auto";
            ipv6.method = "auto";
          };
        };

        environment.etc."NetworkManager/installer-wifi.env".text = ''
          WIFI_SSID=WIFI_SSID_PLACEHOLDER
          WIFI_PSK=WIFI_PASSWORD_PLACEHOLDER
        '';

        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "no";
          };
        };

        users.users.nixos = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpC7kvvPxCPEAAXTWmZ9+8/fUs8F9nIvENaga2aSpjl jarvahl@apex"
          ];
        };

        security.sudo.wheelNeedsPassword = false;

        environment.systemPackages = [ pkgs.networkmanager ];
      })
    ];
  };
}
