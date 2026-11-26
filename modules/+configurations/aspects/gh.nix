{ den, lib, ... }:
lib.mkMerge [
  {
    den.aspects.gh = {
      hjem =
        { pkgs, ... }:
        {
          packages = [ pkgs.gh ];
        };
    };
  }
  {
    den.aspects.gh.hjem =
      { config, user, ... }:
      lib.mkIf (user.hasAspect den.aspects.sops) {
        sops.secrets."github/ssh_key" = {
          mode = "0600";
          path = "${config.home.homeDirectory}/.ssh/id_ed25519_github";
        };

        programs.ssh.settings."github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = config.sops.secrets."github/ssh_key".path;
          IdentitiesOnly = true;
        };
      };
  }
  {
    den.aspects.gh.hjem =
      { osConfig, user, ... }:
      lib.mkIf (user.hasAspect den.aspects.proxy) {
        programs.ssh.settings."github.com".ProxyCommand =
          "${osConfig.sops.templates.ssh-github-proxy.path} %h %p";
      };
  }
  {
    den.aspects.gh.nixos =
      {
        config,
        host,
        pkgs,
        ...
      }:
      lib.mkIf (host.hasAspect den.aspects.proxy) {
        sops.secrets."proxy/https" = { };

        sops.templates.ssh-github-proxy = {
          mode = "0500";
          owner = "nixos";
          path = "/run/secrets-rendered/ssh-github-proxy";
          content = ''
            #!${pkgs.runtimeShell}
            exec ${pkgs.nmap}/bin/ncat \
              --proxy "${config.sops.placeholder."proxy/https"}" \
              --proxy-type http \
              "$@"
          '';
        };
      };
  }
]
