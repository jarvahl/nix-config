{ den, ... }:
{
  den.aspects.gitlab = {
    hjem.sops.secrets."gitlab/host" = { };

    includes = with den.aspects.sops; [
      (template
        {
          content = secrets: ''
            GITLAB_HOST="https://${secrets."gitlab/host"}"
          '';
          mode = "0400";
          name = "glab-environment";
        }
        {
          hjem = { path, pkgs, ... }: {
            packages = [
              (pkgs.writeShellApplication {
                name = "glab";
                text = ''
                  set -a
                  . "${path}"
                  set +a

                  exec ${pkgs.glab}/bin/glab "$@"
                '';
              })
            ];
          };
        }
      )
    ];
  };
}
