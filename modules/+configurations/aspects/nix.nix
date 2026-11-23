{ lib, ... }:
let
  nixExperimentalFeatures = [
    "nix-command"
    "flakes"
    "pipe-operators"
  ];
in
lib.mkMerge [
  {
    _module.args.nixExperimentalFeatures = nixExperimentalFeatures;

    den.aspects.nix.nixos = {
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
    };
  }
  {
    den.aspects.nix.certificates = {
      nixos =
        { lib, ... }:
        let
          caBundle = "/etc/ssl/certs/ca-certificates.crt";
          variables = lib.genAttrs [ "NIX_SSL_CERT_FILE" ] (_: caBundle);
          environment = lib.mapAttrsToList (name: value: "${name}=${value}") variables;
        in
        {
          nix.settings.ssl-cert-file = caBundle;
          systemd.services.nix-daemon.serviceConfig.Environment = environment;
        };
    };
  }
  {
    den.aspects.nix.proxy = {
      nixos =
        { config, ... }:
        {
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
        };
    };
  }
]
