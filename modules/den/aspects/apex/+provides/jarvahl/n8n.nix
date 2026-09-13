{ ... }:
{
  den.aspects.apex.provides.jarvahl = {
    hjem.programs.mcp = {
      enable = true;

      servers."n8n-mcp" = {
        type = "http";
        url = "http://localhost:5678/mcp-server/http";
        bearerToken =
          "!cat /run/secrets/users/jarvahl/n8n/mcp/token";
      };
    };

    nixos.sops.secrets."users/jarvahl/n8n/mcp/token" = {
      owner = "jarvahl";
      mode = "0400";
    };
  };
}
