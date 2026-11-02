{ ... }:

{
  den.aspects."assistant@dvalin" = {
    hjem =
      { config, self', ... }:
      {
        files = {
          ".local/share/gaia/AGENTS.md".source = ./AGENTS.md;
        };

        systemd.services.gaia = {
          environment = {
            AGENT_CWD = "${config.home.homeDirectory}/.local/share/gaia";
            AGENT_MODEL = "gpt-5.6-luna";
            AGENT_NAME = "gaia";
            AGENT_PI_COMMAND = "/etc/profiles/per-user/assistant/bin/pi";
            AGENT_PROVIDER = "openai";
            AGENT_SESSION_DIR = "${config.home.homeDirectory}/.local/state/pi/sessions";
            AGENT_SOCKET = "%t/agents/gaia.sock";
            AGENT_STATE_DIR = "${config.home.homeDirectory}/.local/state/gaia";
          };
          serviceConfig = {
            ExecStart = "${self'.packages.agent}/bin/agent serve";
            Restart = "always";
            RestartSec = 5;
            RuntimeDirectory = "agents";
            WorkingDirectory = "${config.home.homeDirectory}/.local/share/gaia";
          };
          wantedBy = [ "default.target" ];
        };

      };
  };
}
