{ den, ... }:
{
  den.aspects.vmw71 = {
    includes = with den.aspects; [ podman fonts zscaler ];
  };

  den.hosts.x86_64-linux.vmw71 = {
    wsl.enable = true;
    users.nixos-user.userName = "nixos";
  };
}
