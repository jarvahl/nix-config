{ lib, ... }:
lib.mkMerge [
  {
    den.aspects.gh = {
      hjem =
        { pkgs, ... }:
        {
          packages = [ pkgs.gh ];
        };
    };
  }
  {
    den.aspects.gh.sops = {
      hjem =
        { config, ... }:
        {
          sops.secrets."github/ssh_key" = {
            mode = "0600";
            path = "${config.home.homeDirectory}/.ssh/id_ed25519_github";
          };

          files.".ssh/config.d/github".text = ''
            Host github.com
              HostName github.com
              User git
              IdentityFile ${config.sops.secrets."github/ssh_key".path}
              IdentitiesOnly yes
          '';
        };
    };
  }
]
