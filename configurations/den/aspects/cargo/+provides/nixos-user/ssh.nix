{ ... }:
{
  den.aspects.cargo.provides.nixos-user.hjem = { sops, user, ... }: {
    files.".ssh/config".text = ''
      Include ~/.ssh/config.d/*
    '';
    files.".ssh/config.d/github".text = ''
      Host github.com
        HostName github.com
        User git
        IdentityFile ${sops.secrets."users/${user.userName}/github/ssh-key".path}
        IdentitiesOnly yes
    '';
  };
}
