{ ... }:

{
  den.aspects."assistant@dvalin".hjem =
    { config, pkgs, ... }:
    {
      systemd.services.pi-gateway = {
        after = [ "sops-nix.service" ];
        requires = [ "sops-nix.service" ];
        serviceConfig = {
          EnvironmentFile = config.sops.templates."pi-gateway.env".path;
          ExecStart = "${pkgs.pi-gateway}/bin/pi-gateway run -c ${config.home.homeDirectory}/.config/pi-gateway/gaia.yaml";
          Restart = "always";
          RestartSec = 5;
          WorkingDirectory = "${config.home.homeDirectory}/.local/share/gaia";
        };
        wantedBy = [ "default.target" ];
      };
    };
}
