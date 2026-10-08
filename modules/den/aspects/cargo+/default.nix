{ den, ... }:
{
  den = {
    aspects.cargo.includes = with den.aspects; [ podman ];

    hosts.x86_64-linux.cargo = {
      users.nixos-user = {
        classes = [ "hjem" ];
        userName = "nixos";
      };
      wsl.enable = true;
    };
  };
}
