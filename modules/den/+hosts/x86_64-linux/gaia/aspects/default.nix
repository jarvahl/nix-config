{ ... }:
{
  den.aspects.gaia = {
    nixos = { config, ... }: {
      sops = {
        defaultSopsFile = ../secrets.yml;

        secrets = {
          "proxy/http" = { };
          "proxy/https" = { };
          "proxy/noProxy" = { };
          "gitlab/url" = { };
        };

        templates = {
          proxy-environment = {
            owner = "nixos";
            mode = "0400";
            content = ''
              http_proxy="${config.sops.placeholder."proxy/http"}"
              https_proxy="${config.sops.placeholder."proxy/https"}"
              no_proxy="${config.sops.placeholder."proxy/noProxy"}"
              HTTP_PROXY="${config.sops.placeholder."proxy/http"}"
              HTTPS_PROXY="${config.sops.placeholder."proxy/https"}"
              NO_PROXY="${config.sops.placeholder."proxy/noProxy"}"
            '';
          };

          glab-environment = {
            owner = "nixos";
            mode = "0400";
            content = ''
              GITLAB_HOST="${config.sops.placeholder."gitlab/url"}"
            '';
          };
        };
      };

      # Reserve ports for local development services.
      boot.kernel.sysctl."net.ipv4.ip_local_reserved_ports" = "61000-64999";

      systemd = {
        services.nix-daemon.serviceConfig.EnvironmentFile =
          "-${config.sops.templates.proxy-environment.path}";

        user.services.podman.serviceConfig.EnvironmentFile =
          "-${config.sops.templates.proxy-environment.path}";
      };
    };

  };
}
