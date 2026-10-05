{ den, ... }:
{
  den = {
    aspects."jarvahl@zero".includes = with den.aspects; [
      (den.batteries.user-shell "zsh")
      quickshell
      foot
      hyperland
      hypridle
      swaybg
    ];

    hosts.x86_64-linux.zero.users.jarvahl.classes = [ "hjem" ];
  };
}
