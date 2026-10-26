{ flakeConfig, lib, ... }:
let
  hosts = lib.filterAttrs (
    _: nixos: nixos.config.services.tailscale.enable
  ) flakeConfig.nixosConfigurations;
  tags = lib.unique (
    lib.concatLists (lib.mapAttrsToList (_: nixos: nixos.config.services.tailscale.tags) hosts)
  );
in
{
  locals.tailscale_tag_owners = lib.genAttrs (map (tag: "tag:${tag}") tags) (_: [
    "autogroup:admin"
  ]);
}
