{
  config,
  den,
  lib,
  ...
}:
lib.mkMerge [
  {
    den.aspects.tailscale = {
      includes = [
        (den.batteries.import-tree ./.)
      ];

      nixos =
        { config, pkgs, ... }:
        {
          networking.firewall.trustedInterfaces = [ "tailscale0" ];
          services.tailscale = {
            enable = true;
            tags = [ "managed" ];
          };

          systemd.services.tailscaled-logout = lib.mkIf (config.services.tailscale.authKeyFile != null) {
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
        };
    };
  }
  {
    den.aspects.tailscale.service.__functor =
      _self:
      {
        comment ? null,
        name,
        port,
        servicePort ? 443,
      }:
      {
        nixos.services.tailscale.services.${name} = {
          inherit port servicePort;
        }
        // lib.optionalAttrs (comment != null) { inherit comment; };
      };
  }
  {
    den.aspects.tailscale.tags.__functor = _self: tags: {
      nixos.services.tailscale.tags = tags;
    };
  }
  {
    perSystem.terranix.terranixConfigurations.terranix.modules = [
      {
        _module.args.flakeConfig = {
          inherit (config.flake) nixosConfigurations;
        };
      }
    ];
  }
]
