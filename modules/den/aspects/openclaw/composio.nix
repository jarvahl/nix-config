{ ... }:
{
  den.aspects.openclaw.composio.hjem = {
    programs.openclaw.config.mcp.servers.composio = {
      enabled = true;
      headers.x-api-key = "\${COMPOSIO_API_KEY}";
      transport = "streamable-http";
      url = "\${COMPOSIO_MCP_URL}";
    };
  };
}
