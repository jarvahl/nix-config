{ den, ... }:
{
  den.aspects.gaia = {
    includes = with den.aspects; [ podman fonts zscaler ];
  };

  den.hosts.x86_64-linux.gaia = {
    wsl.enable = true;
    users.nixos-user.userName = "nixos";
  };
}
