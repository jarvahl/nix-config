{ den, lib, ... }:
let
  inherit (den.aspects) certificates proxy;
  nixExperimentalFeatures = [
    "nix-command"
    "flakes"
    "pipe-operators"
  ];
in
{
  _module.args.nixExperimentalFeatures = nixExperimentalFeatures;

  den.aspects.nix.nixos =
    { config, host, ... }:
    lib.mkMerge [
      {
        nix.settings.experimental-features = nixExperimentalFeatures;
        nix.settings.trusted-users = [
          "root"
          "@wheel"
        ];
        programs.nix-ld.enable = true;
        services.harmonia.gc = {
          automatic = true;
          dates = "daily";
          deleteOlderThan = "30d";
          enable = true;
          ensureFree = "20%";
          keepRecent = "2d";
          randomizedDelaySec = "1h";
          persistent = true;
        };
      }
      (lib.mkIf (host.hasAspect certificates) {
        nix.settings.ssl-cert-file = "/etc/ssl/certs/ca-certificates.crt";
        systemd.services.nix-daemon.serviceConfig.Environment = [
          "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
        ];
      })
      (lib.mkIf (host.hasAspect proxy) {
        sops.secrets = {
          "proxy/http" = { };
          "proxy/https" = { };
          "proxy/noProxy" = { };
        };

        sops.templates.nix-proxy-environment = {
          mode = "0400";
          owner = "root";
          content = ''
            http_proxy="${config.sops.placeholder."proxy/http"}"
            https_proxy="${config.sops.placeholder."proxy/https"}"
            no_proxy="${config.sops.placeholder."proxy/noProxy"}"
            HTTP_PROXY="${config.sops.placeholder."proxy/http"}"
            HTTPS_PROXY="${config.sops.placeholder."proxy/https"}"
            NO_PROXY="${config.sops.placeholder."proxy/noProxy"}"
          '';
        };

        systemd.services.nix-daemon.serviceConfig.EnvironmentFile = [
          config.sops.templates.nix-proxy-environment.path
        ];
      })
    ];
}
