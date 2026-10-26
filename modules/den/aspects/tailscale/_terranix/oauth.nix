{ flakeConfig, lib, ... }:
let
  hosts = lib.filterAttrs (
    _: nixos: nixos.config.services.tailscale.enable
  ) flakeConfig.nixosConfigurations;
in
{
  output.tailscale_oauth_keys = {
    sensitive = true;
    value = lib.mapAttrs (host: _: "\${tailscale_oauth_client.${host}.key}") hosts;
  };

  resource.tailscale_oauth_client = lib.mapAttrs (host: nixos: {
    depends_on = [ "tailscale_acl.tags" ];
    description = host;
    scopes = [ "auth_keys" ];
    tags = map (tag: "tag:${tag}") nixos.config.services.tailscale.tags;
  }) hosts;

  terraform.required_providers.tailscale.source = "tailscale/tailscale";
}
