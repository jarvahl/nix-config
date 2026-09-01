{ lib, ... }:
let
  bundle = "/etc/ssl/certs/ca-certificates.crt";

  variables = lib.genAttrs [
    "NIX_SSL_CERT_FILE"
    "SSL_CERT_FILE"
    "CURL_CA_BUNDLE"
    "GIT_SSL_CAINFO"
  ]
    (_: bundle);

  systemdEnvironment =
    lib.mapAttrsToList (name: value: "${name}=${value}") variables;
in
{
  den.aspects.ca = {
    provides.to-users = {
      hjem = {
        environment.sessionVariables = variables;

        rum.programs.git.settings.http.sslCAInfo = bundle;
      };
    };

    nixos = { config, ... }: {
      nix.settings.ssl-cert-file = bundle;

      systemd.services.nix-daemon.serviceConfig.Environment =
        lib.mkAfter systemdEnvironment;

      systemd.user.services.podman.serviceConfig.Environment =
        lib.mkIf config.virtualisation.podman.enable (lib.mkAfter systemdEnvironment);
    };
  };
}
