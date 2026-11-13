{ lib, ... }:

lib.mkMerge [
  {
    den.aspects.git.hjem =
      { config, lib, ... }:
      {
        programs.git.enable = true;
        programs.zsh.bundle.git.enable = lib.mkDefault config.programs.git.enable;
        rum.programs.git.settings = {
          format.pretty = "oneline";
          log.decorate = "short";
        };
      };
  }
  {
    den.aspects.git.certificates = {
      provides.to-users.hjem.rum.programs.git.settings.http.sslCAInfo =
        "/etc/ssl/certs/ca-certificates.crt";

      hjem =
        { ... }:
        {
          environment.sessionVariables.GIT_SSL_CAINFO = "/etc/ssl/certs/ca-certificates.crt";
        };
    };
  }
  {
    den.default.nixos.hjem.extraModules = [
      ({ lib, ... }: {
        imports = [
          (lib.mkAliasOptionModule [ "programs" "git" "enable" ] [ "rum" "programs" "git" "enable" ])
        ];
      })
    ];
  }
]
