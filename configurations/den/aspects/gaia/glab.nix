{ ... }:
{
  den.aspects.gaia.nixos = { config, ... }: {
    sops.secrets."gitlab/host" = { };
    sops.templates.glab-environment = {
      owner = "nixos";
      mode = "0400";
      content = ''
        GITLAB_HOST="https://${config.sops.placeholder."gitlab/host"}"
      '';
    };
  };
}
