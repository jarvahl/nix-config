{ config, lib, ... }:
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
    lib.nameValuePair "tailscale-${name}" {
      after = [ "tailscaled.service" ];
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
