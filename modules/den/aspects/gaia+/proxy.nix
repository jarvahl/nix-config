{ lib, ... }:

{
  den.aspects.gaia.nixos =
    { config, ... }:
    let
      inherit (config) sops;

      proxy = name: sops.placeholder."proxy/${name}";
      proxyFile = sops.templates.proxy-environment.path;

      withProxy = _: {
        serviceConfig.EnvironmentFile = [ proxyFile ];
      };
    in
    {
      sops.secrets = {
        "proxy/http" = { };
        "proxy/https" = { };
        "proxy/noProxy" = { };
      };

      sops.templates.proxy-environment = {
        owner = "nixos";
        mode = "0400";
        content = ''
          http_proxy="${proxy "http"}"
          https_proxy="${proxy "https"}"
          no_proxy="${proxy "noProxy"}"
          HTTP_PROXY="${proxy "http"}"
          HTTPS_PROXY="${proxy "https"}"
          NO_PROXY="${proxy "noProxy"}"
        '';
      };

      environment.shellInit = ''
        if [ -r "${proxyFile}" ]; then
          set -a
          . "${proxyFile}"
          set +a
        fi
      '';

      systemd = {
        services = lib.genAttrs [
          "nix-daemon"
        ] withProxy;

        user.services = lib.genAttrs [
          "podman"
        ] withProxy;
      };
    };
}
