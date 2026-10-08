{ den, ... }:
{
  den = {
    aspects.gaia.includes = with den.aspects; [ podman ];

    hosts.x86_64-linux.gaia = {
      users.nixos-user = {
        classes = [ "hjem" ];
        userName = "nixos";
      };
      wsl.enable = true;
    };
  };
}
