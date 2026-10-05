{ den, ... }:
{
  den = {
    aspects."jarvahl@zero".includes = with den.aspects; [
      dynamic-island
      hyperland
    ];

    hosts.x86_64-linux.zero.users.jarvahl = { };
  };
}
