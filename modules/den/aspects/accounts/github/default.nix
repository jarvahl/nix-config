{ ... }:
{
  den.aspects.accounts.github.hjem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages = [ pkgs.gh ];

      sops.secrets."github/ssh-key" = {
        mode = "0600";
        path = "${config.home.homeDirectory}/.ssh/keys.d/github";
      };

      files.".ssh/config.d/github".text = ''
        Host github.com
          HostName github.com
          User git
          IdentityFile ${config.sops.secrets."github/ssh-key".path}
          IdentitiesOnly yes
      '';
    };
}
