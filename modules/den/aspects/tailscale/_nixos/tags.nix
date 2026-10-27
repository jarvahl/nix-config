{ config, lib, ... }:
let
  cfg = config.services.tailscale;
  flag = "--advertise-tags=" + lib.concatMapStringsSep "," (tag: "tag:${tag}") (lib.unique cfg.tags);
in
{
  config = lib.mkIf cfg.enable {
    services.tailscale.extraUpFlags = [
      flag
      "--hostname=${config.networking.hostName}"
    ];

    systemd.services.tailscaled-tags = {
      after = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
      ];
      wantedBy = [ "tailscaled.service" ];
      wants = [ "tailscaled-autoconnect.service" ];
      path = [ cfg.package ];
      serviceConfig.Type = "oneshot";
      script = "tailscale up ${lib.escapeShellArgs cfg.extraUpFlags}";
    };
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
