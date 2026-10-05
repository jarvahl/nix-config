{ den, ... }:
{
  den = {
    aspects."jarvahl@zero".includes =
      (with den.aspects; [
        quickshell
        foot
        hyperland
        hypridle
        swaybg
      ])
      ++ (with den.batteries; [
        (user-shell "zsh")
      ]);

    hosts.x86_64-linux.zero.users.jarvahl.classes = [ "hjem" ];
  };
}
