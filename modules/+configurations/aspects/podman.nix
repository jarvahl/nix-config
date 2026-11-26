{ den, lib, ... }:
let
  inherit (den.aspects) certificates proxy;
in
lib.mkMerge [
  {
    den.aspects.podman.nixos =
      { config, host, ... }:
      lib.mkMerge [
        {
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
        }
        (lib.mkIf (host.hasAspect certificates) {
          systemd.user.services.podman.serviceConfig.Environment = [
            "CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt"
            "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
          ];
        })
        (lib.mkIf (host.hasAspect proxy) {
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
        })
      ];
  }
  {
    den.aspects.podman = {
      provides.to-users.user.extraGroups = [ "podman" ];
    };
  }
]
