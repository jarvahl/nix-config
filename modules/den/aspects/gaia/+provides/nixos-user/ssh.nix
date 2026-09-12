{ ... }:
{
  den.aspects.gaia.provides.nixos-user.hjem = { pkgs, sops, user, ... }: {
    files.".ssh/config".text = ''
      Include ~/.ssh/config.d/*
    '';
    files.".ssh/config.d/github".text = ''
      Host github.com
        HostName ssh.github.com
        Port 443
        User git
        IdentityFile ${sops.secrets."users/${user.userName}/github/ssh-key".path}
        IdentitiesOnly yes
        StrictHostKeyChecking accept-new
        UserKnownHostsFile ~/.ssh/known_hosts
        ProxyCommand sh -c '. ${sops.templates."proxy-environment".path}; proxy="''${http_proxy#*://}"; exec ${pkgs.netcat}/bin/nc -X connect -x "$proxy" "$1" "$2"' _ %h %p
    '';
  };
}
