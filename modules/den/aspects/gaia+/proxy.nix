{ lib, ... }:

let
  sshProxyFile = "/run/secrets-rendered/ssh-github-proxy";
in
{
  den.aspects.gaia = {
    nixos =
      { config, pkgs, ... }:
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

        sops.templates = {
          proxy-environment = {
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

          ssh-github-proxy = {
            owner = "nixos";
            mode = "0500";
            path = sshProxyFile;
            content = ''
              #!${pkgs.runtimeShell}
              set -a
              . ${proxyFile}
              set +a

              exec ${pkgs.nmap}/bin/ncat \
                --proxy "$https_proxy" \
                --proxy-type http \
                "$@"
            '';
          };
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

    provides.to-users.hjem.files.".ssh/config.d/github-proxy".text = ''
      Host github.com
        HostName github.com
        User git
        ProxyCommand ${sshProxyFile} %h %p
    '';
  };
}
