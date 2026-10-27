{ ... }:
{
  den.aspects.openclaw.composio.hjem = {
    files.".openclaw/workspace/TOOLS.md".text = ''
      # Tool preferences

      For external services, first discover and use the available Composio tools.
      Fall back to other integrations or browser automation only when Composio
      does not support the task or fails. Do not repeat potentially destructive
      actions if the outcome of the first attempt is uncertain.
    '';

    programs.openclaw.config.mcp.servers.composio = {
      enabled = true;
      headers.x-api-key = "\${COMPOSIO_API_KEY}";
      transport = "streamable-http";
      url = "\${COMPOSIO_MCP_URL}";
    };
  };
}
