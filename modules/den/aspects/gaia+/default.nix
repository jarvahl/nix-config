{ ... }:
{
  den = {
    hosts.x86_64-linux.gaia = {
      users.nixos-user = {
        classes = [ "hjem" ];
        userName = "nixos";
      };
      wsl.enable = true;
    };
  };
}
