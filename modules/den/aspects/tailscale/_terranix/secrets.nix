{
  flakeConfig,
  lib,
  pkgs,
  ...
}:
let
  hosts = lib.filterAttrs (
    _: nixos: nixos.config.services.tailscale.enable
  ) flakeConfig.nixosConfigurations;
  syncSecret = pkgs.writeShellApplication {
    name = "tailscale-sync-secret";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.sops
    ];
    text = ''
      : "''${TAILSCALE_AUTH_KEY:?Missing OAuth secret}"
      : "''${SOPS_FILE:?Missing destination}"
      test -f "$SOPS_FILE"

      temporary="$(mktemp "$(dirname "$SOPS_FILE")/.tailscale-secret.XXXXXX.yaml")"
      trap 'rm -f -- "$temporary"' EXIT
      cp -- "$SOPS_FILE" "$temporary"

      jq -cn 'env.TAILSCALE_AUTH_KEY' |
        sops set --idempotent --value-stdin "$temporary" '["tailscale"]["auth_key"]'

      if ! cmp -s "$SOPS_FILE" "$temporary"; then
        chmod --reference="$SOPS_FILE" "$temporary"
        mv -- "$temporary" "$SOPS_FILE"
      fi
    '';
  };
in
{
  resource.terraform_data = lib.mapAttrs' (
    host: _:
    let
      file = flakeConfig.hostSecretFiles.${host};
    in
    lib.nameValuePair "tailscale_secret_${host}" {
      provisioner = [
        {
          local-exec = {
            command = lib.getExe syncSecret;
            environment = {
              SOPS_FILE = file;
              TAILSCALE_AUTH_KEY = "\${tailscale_oauth_client.${host}.key}";
            };
            working_dir = "\${path.root}";
          };
        }
      ];
      triggers_replace = {
        client_id = "\${tailscale_oauth_client.${host}.id}";
        inherit file;
      };
    }
  ) hosts;
}
