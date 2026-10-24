{ den, lib, ... }:

let
  bundle = "/etc/ssl/certs/ca-certificates.crt";

  variables = lib.genAttrs [
    "NIX_SSL_CERT_FILE"
    "SSL_CERT_FILE"
    "CURL_CA_BUNDLE"
    "GIT_SSL_CAINFO"
  ] (_: bundle);

  shellExports = lib.concatMapStringsSep "\n" (
    { name, value }: "export ${name}=${lib.escapeShellArg value}"
  ) (lib.attrsToList variables);

  systemdEnvironment = lib.mapAttrsToList (name: value: "${name}=${value}") variables;

  withCertificates = _: {
    serviceConfig.Environment = lib.mkAfter systemdEnvironment;
  };
in
with den.lib;
{
  den.aspects.certificates = callable {
    nixos = {
      environment.shellInit = shellExports;

      nix.settings.ssl-cert-file = bundle;

      systemd = {
        services = lib.genAttrs [
          "nix-daemon"
        ] withCertificates;

        user.services = lib.genAttrs [
          "podman"
        ] withCertificates;
      };
    };

    provides.to-users.hjem.rum.programs.git.settings.http.sslCAInfo = bundle;
  };
}
