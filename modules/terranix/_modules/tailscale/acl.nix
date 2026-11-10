{
  locals.tailscale_policy = {
    grants = [
      {
        dst = [ "*" ];
        ip = [ "*" ];
        src = [ "*" ];
      }
    ];
    nodeAttrs = [
      {
        attr = [ "funnel" ];
        target = [ "autogroup:member" ];
      }
    ];
    ssh = [
      {
        action = "check";
        dst = [ "autogroup:self" ];
        src = [ "autogroup:member" ];
        users = [
          "autogroup:nonroot"
          "root"
        ];
      }
    ];
  };

  resource.tailscale_acl.tags = {
    acl = ''
      ''${jsonencode(merge(local.tailscale_policy, {
        autoApprovers = {
          services = local.tailscale_service_approvers
        }
        tagOwners = local.tailscale_tag_owners
      }))}
    '';
    lifecycle.prevent_destroy = true;
    overwrite_existing_content = true;
    reset_acl_on_destroy = false;
  };

  terraform.required_providers.tailscale.source = "tailscale/tailscale";
}
