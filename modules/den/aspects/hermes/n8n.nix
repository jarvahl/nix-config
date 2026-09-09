{ den, ... }:
{
  den.aspects.hermes = {
    nixos.services.n8n = {
      enable = true;
      openFirewall = false;

      environment = {
        N8N_PORT = "5678";
        N8N_DIAGNOSTICS_ENABLED = "false";
        N8N_SECURE_COOKIE = "false";
        N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
      };
    };

    includes = [ (den.batteries.unfree [ "n8n" ]) ];
  };
}
