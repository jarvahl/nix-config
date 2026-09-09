{ ... }:
{
  den.hosts.x86_64-linux = {
    cargo = {
      users.nixos-user.userName = "nixos";
    };

    apex = {
      users.jarvahl = { };
    };

    hermes = {
      users.nixos-user.userName = "nixos";
    };

    gaia = {
      users.nixos-user.userName = "nixos";
    };
  };
}
