{ inputs, ... }:

{
  den.aspects."assistant@dvalin" = {
    hjem =
      {
        config,
        lib,
        pkgs,
        self',
        ...
      }:
      let
        gaiaPi =
          (inputs.pi.lib.mkCodingAgent {
            inherit pkgs;
            modules = [
              {
                pi.coding-agent.extensions = with self'.packages; [
                  "${pi-core-skill-tool}/pi-core-skill-tool/index.ts"
                  "${pi-memory}/pi-memory/index.ts"
                  "${pi-self-compact}/pi-self-compact/index.ts"
                ];
                pi.coding-agent.rules = ./AGENTS.md;
                pi.coding-agent.skills = [ ./skills/telegram-notify ];
              }
            ];
          }).package;
      in
      {
        systemd.services.gaia = {
          environment = {
            PATH = lib.mkForce (
              lib.makeBinPath [
                pkgs.bash
                pkgs.coreutils
                pkgs.findutils
                pkgs.gnugrep
                pkgs.gnused
                pkgs.nodejs
                pkgs.systemd
              ]
            );
            AGENT_CWD = "${config.home.homeDirectory}/.local/share/gaia";
            AGENT_IDLE_TIMEOUT_MS = "300000";
            AGENT_MODEL = "gpt-5.6-luna";
            AGENT_NAME = "gaia";
            AGENT_PI_COMMAND = "${gaiaPi}/bin/pi";
            AGENT_PROVIDER = "openai";
            GAIA_DEFAULT_CONVERSATION = "telegram:1919581469";
            GAIA_TELEGRAM_SOCKET = "%t/agents/telegram-for-gaia/telegram.sock";
            AGENT_SESSION_DIR = "${config.home.homeDirectory}/.local/state/pi/sessions";
            AGENT_SESSION_ID = "gaia";
            AGENT_SOCKET = "%t/agents/gaia/gaia.sock";
            AGENT_STATE_DIR = "${config.home.homeDirectory}/.local/state/gaia";
            PI_MEMORY_DIR = "${config.home.homeDirectory}/.local/share/gaia/memory";
            PI_MEMORY_EXIT_SUMMARY = "1";
            PI_MEMORY_SNAPSHOT = "stable";
          };
          serviceConfig = {
            ExecStart = "${self'.packages.agent}/bin/agent serve";
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %t/agents/gaia";
            Restart = "always";
            RestartSec = 5;
            WorkingDirectory = "${config.home.homeDirectory}/.local/share/gaia";
          };
          wantedBy = [ "default.target" ];
        };

      };
  };
}
