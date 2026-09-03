{ ... }:
{
  den.hosts.x86_64-linux.iter = {
    wsl.enable = true;
    users.nixos-user.userName = "nixos";
  };
}
