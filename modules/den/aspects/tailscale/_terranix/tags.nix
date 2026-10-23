{ lib, tailscaleTagsByHost, ... }:
let
  tags = lib.unique (lib.concatLists (builtins.attrValues tailscaleTagsByHost));
in
{
  data.tailscale_acl.current = { };

  locals = {
    tailscale_policy = "\${jsondecode(data.tailscale_acl.current.json)}";
    tailscale_tag_owners = lib.genAttrs (map (tag: "tag:${tag}") tags) (_: [ "autogroup:admin" ]);
  };

  resource.tailscale_acl.tags = {
    # Preserve the live policy and existing owners; only missing tags get the default owner.
    acl = "\${jsonencode(merge(local.tailscale_policy, {tagOwners = merge(local.tailscale_tag_owners, lookup(local.tailscale_policy, \"tagOwners\", {}))}))}";
    lifecycle.prevent_destroy = true;
    overwrite_existing_content = false;
    reset_acl_on_destroy = false;
  };

  terraform.required_providers.tailscale.source = "tailscale/tailscale";
}
