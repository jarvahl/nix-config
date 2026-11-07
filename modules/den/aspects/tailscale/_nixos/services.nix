{ config, lib, ... }:
let
  serviceNames = builtins.attrNames config.services.tailscale.services;
in
{
  options.services.tailscale.services = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          comment = lib.mkOption {
            default = null;
            type = lib.types.nullOr lib.types.str;
          };
          port = lib.mkOption {
            type = lib.types.port;
          };
          servicePort = lib.mkOption {
            default = 443;
            type = lib.types.port;
          };
        };
      }
    );
  };

  config.systemd.services = lib.mapAttrs' (
    name: service:
    let
      previousServices =
        let
          takeBefore =
            names:
            if names == [ ] then
              [ ]
            else if builtins.head names == name then
              [ ]
            else
              [ (builtins.head names) ] ++ takeBefore (builtins.tail names);
        in
        takeBefore serviceNames;
    in
    lib.nameValuePair "tailscale-${name}" {
      after = [ "tailscaled.service" ] ++ map (other: "tailscale-${other}.service") previousServices;
      description = "Publish ${name} through Tailscale";
      serviceConfig = {
        ExecStart =
          "${config.services.tailscale.package}/bin/tailscale serve "
          + "--service=svc:${name} "
          + "http://127.0.0.1:${toString service.port}";
        RemainAfterExit = true;
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
      wants = [ "tailscaled.service" ];
    }
  ) config.services.tailscale.services;
}
