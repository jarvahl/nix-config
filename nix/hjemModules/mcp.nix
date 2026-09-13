{ config, lib, ... }:
let
  cfg = config.programs.mcp;
in
{
  options.programs.mcp = {
    enable = lib.mkEnableOption "MCP";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages required by configured MCP servers.";
    };

    servers = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "MCP server definitions.";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = cfg.packages;

    files.".config/mcp/mcp.json".text = builtins.toJSON {
      mcpServers = cfg.servers;
    };
  };
}
