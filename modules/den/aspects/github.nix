{ den, ... }:
{
  den.aspects.github = {
    includes = with den.aspects.sops; [
      (secret
        {
          mode = "0600";
          name = "github/ssh-key";
          path = ".ssh/keys.d/github";
        }
        {
          hjem = { path, ... }: {
            files.".ssh/config.d/github".text = ''
              Host github.com
                HostName github.com
                User git
                IdentityFile ${path}
                IdentitiesOnly yes
            '';
          };
        }
      )
    ];

    hjem = { pkgs, ... }: {
      packages = [ pkgs.gh ];
    };
  };
}
