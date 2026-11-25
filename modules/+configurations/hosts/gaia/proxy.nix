{
  den.aspects.proxy.nixos =
    { config, ... }:
    {
      sops.secrets = {
        "proxy/http" = { };
        "proxy/https" = { };
        "proxy/noProxy" = { };
      };

      sops.templates.proxy-shell-environment = {
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

      environment.shellInit = ''
        if [ -r "${config.sops.templates.proxy-shell-environment.path}" ]; then
          set -a
          . "${config.sops.templates.proxy-shell-environment.path}"
          set +a
        fi
      '';
    };
}
