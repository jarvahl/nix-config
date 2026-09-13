{ ... }:
{
  den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
    programs.mcp = {
      enable = true;

      packages = [ pkgs.mcp-nixos ];

      servers.nixos = {
        command = "mcp-nixos";
        lifecycle = "lazy";
      };
    };
  };
}
