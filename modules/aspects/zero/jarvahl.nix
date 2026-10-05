{ den, ... }:
{
  den = {
    aspects."jarvahl@zero".includes = with den.aspects; [
      dynamic-island
      foot
      hyperland
      hypridle
      swaybg
    ];

    hosts.x86_64-linux.zero.users.jarvahl.classes = [ "hjem" ];
  };
}
