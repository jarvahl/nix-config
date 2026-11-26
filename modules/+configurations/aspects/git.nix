{ den, lib, ... }:
let
  inherit (den.aspects) certificates;
in
lib.mkMerge [
  {
    den.aspects.git.hjem =
      { user, ... }:
      {
        programs.git.enable = true;
        rum.programs.git.settings = {
          format.pretty = "oneline";
          log.decorate = "short";
        };
        environment.sessionVariables = lib.mkIf (user.hasAspect certificates) {
          GIT_SSL_CAINFO = "/etc/ssl/certs/ca-certificates.crt";
        };
      };
  }
  {
    den.aspects.git.provides.to-users.hjem =
      { user, ... }:
      lib.mkIf (user.hasAspect certificates) {
        rum.programs.git.settings.http.sslCAInfo = "/etc/ssl/certs/ca-certificates.crt";
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
