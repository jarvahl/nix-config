{ den, ... }:
{
  den.aspects.github = {
    includes = with den.aspects.sops; [
      (secret
        {
          mode = "0600";
          name = "ssh/identity";
          path = ".ssh/id_ed25519";
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
