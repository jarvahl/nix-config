{ ... }:
{
  den.aspects.hyperland.autologin.nixos =
    { pkgs, user, ... }:
    {
      services.greetd = {
        enable = true;
        settings = rec {
          initial_session = {
            command = "${pkgs.uwsm}/bin/uwsm start -- hyprland-uwsm.desktop";
            user = user.userName;
          };

          default_session = initial_session;
        };
      };
    };
}
