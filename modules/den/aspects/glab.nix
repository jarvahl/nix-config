{ lib, ... }:
lib.mkMerge [
  {
    den.aspects.glab = { };
  }
  {
    den.aspects.glab.sops = {
      hjem =
        { config, pkgs, ... }:
        {
          packages = [
            (pkgs.writeShellApplication {
              name = "glab";
              text = ''
                set -a
                . "${config.sops.templates.glab-environment.path}"
                set +a

                exec ${pkgs.glab}/bin/glab "$@"
              '';
            })
          ];

          sops.secrets."gitlab/host" = { };

          sops.templates.glab-environment = {
            content = ''
              GITLAB_HOST="https://${config.sops.placeholder."gitlab/host"}"
            '';
            mode = "0400";
          };
        };
    };
  }
]
