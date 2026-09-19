{ ... }:
{
  den.aspects.apex.provides.jarvahl = {
    hjem = { pkgs, ... }:
      {
        files.".config/hyprcage/config.toml".source = pkgs.writeText "hyprcage-config.toml" ''
          [screen]
          width = 1280
          height = 800
          max_width = 3840
          max_height = 2160
          max_per_session = 4
          mirror = true
          notify = true

          [workspaces]
          mirror = [6, 9]

          [mirror]
          group = "session"
          per_workspace = 4
          fps = 30

          [lifecycle]
          safety_timer = "15m"

          [cage]
          renderer = "auto"
          render_device = ""
        '';

        programs.mcp.servers.hyprcage = {
          command = "${pkgs.hyprcage}/bin/hyprcage";
          args = [ "mcp" ];
          lifecycle = "lazy";
        };

        programs.pi = {
          extraPackages = [ pkgs.hyprcage ];
          skills.hyprcage = "${pkgs.hyprcage}/share/hyprcage/skills/hyprcage";
        };
      };

    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.cage pkgs.hyprcage ];
    };
  };
}
