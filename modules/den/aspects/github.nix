{ den, ... }:
{
  den.aspects.github = {
    includes = with den.aspects.sops; [
      (secret {
        includes = [
          {
            hjem = { config, ... }: {
              files.".ssh/config.d/github".text = ''
                Host github.com
                  HostName github.com
                  User git
                  IdentityFile ${config.sops.secrets."github/ssh-key".path}
                  IdentitiesOnly yes
              '';
            };
          }
        ];
        mode = "0600";
        name = "github/ssh-key";
        path = ".ssh/keys.d/github";
      })
    ];

    hjem = { pkgs, ... }: {
      packages = [ pkgs.gh ];
    };
  };
}
