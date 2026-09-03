{ den, ... }:
{
  den.aspects.terra = {
    includes =
      (with den.aspects; [
        tailscale
        ssh
        podman
        fonts
      ])
      ++ [ (den.batteries.import-tree ./aspects/_modules) ];
  };

  den.hosts.x86_64-linux.terra = {
    users.jarvahl = { };
  };
}
