{ ... }:
{
  den.hosts.x86_64-linux = {
    probook = {
      users.nixos-user.userName = "nixos";
    };

    thinkbook = {
      users.jarvahl = { };
    };

    vmw71 = {
      users.nixos-user.userName = "nixos";
    };
  };
}
