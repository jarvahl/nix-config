{ ... }:
{
  den.aspects.apex.nixos = { pkgs, ... }: {
    services.greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.uwsm}/bin/uwsm start -- hyprland-uwsm.desktop";
          user = "jarvahl";
        };

        default_session = initial_session;
      };
    };
  };
}
