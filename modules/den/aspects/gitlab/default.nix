{ ... }:
{
  den.aspects.gitlab.hjem =
    { config, pkgs, ... }:
    let
      glab = pkgs.writeShellApplication {
        name = "glab";
        text = ''
          set -a
          . "${config.sops.templates.glab-environment.path}"
          set +a

          exec ${pkgs.glab}/bin/glab "$@"
        '';
      };
    in
    {
      packages = [ glab ];

      sops.secrets."gitlab/host" = { };

      sops.templates.glab-environment = {
        mode = "0400";
        content = ''
          GITLAB_HOST="https://${config.sops.placeholder."gitlab/host"}"
        '';
      };
    };
}
