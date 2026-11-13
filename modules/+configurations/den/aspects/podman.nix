{ lib, ... }:

lib.mkMerge [
  {
    den.aspects.podman = {
      nixos = {
        virtualisation = {
          containers.enable = true;
          oci-containers.backend = "podman";

          podman = {
            defaultNetwork.settings.dns_enabled = true;
            dockerCompat = true;
            dockerSocket.enable = true;
            enable = true;
          };
        };
      };

      provides.to-users.user.extraGroups = [ "podman" ];
    };
  }
  {
    den.aspects.podman.certificates = {
      nixos =
        { lib, ... }:
        let
          caBundle = "/etc/ssl/certs/ca-certificates.crt";
          variables = lib.genAttrs [
            "CURL_CA_BUNDLE"
            "SSL_CERT_FILE"
          ] (_: caBundle);
          environment = lib.mapAttrsToList (name: value: "${name}=${value}") variables;
        in
        {
          systemd.user.services.podman.serviceConfig.Environment = environment;
        };
    };
  }
  {
    den.aspects.podman.proxy = {
      nixos =
        { config, ... }:
        {
          sops.secrets = {
            "proxy/http" = { };
            "proxy/https" = { };
            "proxy/noProxy" = { };
          };

          sops.templates.podman-proxy-environment = {
            mode = "0400";
            owner = "root";
            content = ''
              HTTP_PROXY="${config.sops.placeholder."proxy/http"}"
              HTTPS_PROXY="${config.sops.placeholder."proxy/https"}"
              NO_PROXY="${config.sops.placeholder."proxy/noProxy"}"
            '';
          };

          systemd.user.services.podman.serviceConfig.EnvironmentFile = [
            config.sops.templates.podman-proxy-environment.path
          ];
        };
    };
  }
]
