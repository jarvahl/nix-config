{ config, lib, ... }:
let
  cfg = config.services.tailscale;
  flag = "--advertise-tags=" + lib.concatMapStringsSep "," (tag: "tag:${tag}") (lib.unique cfg.tags);
in
{
  config.services.tailscale = lib.mkIf cfg.enable {
    extraSetFlags = [ flag ];
    extraUpFlags = [ flag ];
  };

  options.services.tailscale.tags = lib.mkOption {
    default = [ ];
    description = "Advertised device tags, without the tag: prefix.";
    example = [
      "server"
      "services"
    ];
    type = lib.types.listOf (lib.types.strMatching "[a-zA-Z][a-zA-Z0-9-]*");
  };
}
