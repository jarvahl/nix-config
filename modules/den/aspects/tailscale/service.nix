{ ... }:
let
  service =
    {
      name,
      port,
    }:
    {
      nixos =
        { config, ... }:
        {
          systemd.services."tailscale-${name}" = {
            after = [ "tailscaled.service" ];
            description = "Publish ${name} through Tailscale";
            serviceConfig = {
              ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --service=svc:${name} http://127.0.0.1:${toString port}";
              RemainAfterExit = true;
              Type = "oneshot";
            };
            wantedBy = [ "multi-user.target" ];
            wants = [ "tailscaled.service" ];
          };
        };
    };
in
{
  den.aspects.tailscale.service.__functor = _self: service;
}
