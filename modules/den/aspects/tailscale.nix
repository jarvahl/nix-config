{ lib, ... }:
{
  den.aspects.tailscale.nixos =
    { config, pkgs, ... }:
    {
      options.services.tailscale.services = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.port = lib.mkOption {
              type = lib.types.port;
            };
          }
        );
      };

      config = {
        networking.firewall.trustedInterfaces = [ "tailscale0" ];
        services.tailscale = {
          enable = true;
          extraUpFlags = [ "--advertise-tags=tag:managed" ];
        };

        systemd.services = lib.mkMerge [
          (lib.mapAttrs' (
            name: service:
            lib.nameValuePair "tailscale-${name}" {
              after = [ "tailscaled.service" ];
              description = "Publish ${name} through Tailscale";
              serviceConfig = {
                ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --service=svc:${name} http://127.0.0.1:${toString service.port}";
                RemainAfterExit = true;
                Type = "oneshot";
              };
              wantedBy = [ "multi-user.target" ];
              wants = [ "tailscaled.service" ];
            }
          ) config.services.tailscale.services)
          (lib.optionalAttrs (config.services.tailscale.authKeyFile != null) {
            tailscaled-logout = {
              after = [ "tailscaled.service" ];
              before = [ "tailscaled-autoconnect.service" ];
              description = "Log out Tailscale before autoconnect";
              path = [
                config.services.tailscale.package
                pkgs.coreutils
                pkgs.jq
              ];
              requires = [ "tailscaled.service" ];
              script = ''
                previous=/var/lib/tailscale/nixos-auth-key

                if [[ -e "$previous" ]] && ! cmp -s ${config.services.tailscale.authKeyFile} "$previous"; then
                  if tailscale status --json --peers=false | jq -e '.BackendState == '"'"'Running'"'"' >/dev/null; then
                    tailscale logout
                  fi
                fi

                install -D -m 0600 ${config.services.tailscale.authKeyFile} "$previous"
              '';
              serviceConfig.Type = "oneshot";
            };
          })
        ];
      };
    };
}
