{ den, ... }:
{
  den = {
    aspects."jarvahl@zero".includes =
      (with den.aspects; [
        # UI
        foot
        hyperland
        hyperland.autologin
        hypridle
        quickshell
        swaybg

        # Console
        zsh
      ])
      ++ (with den.batteries; [
        (user-shell "zsh")
      ]);

    hosts.x86_64-linux.zero.users.jarvahl.classes = [ "hjem" ];
  };
}
