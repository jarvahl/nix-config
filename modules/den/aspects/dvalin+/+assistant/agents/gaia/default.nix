{ den, inputs, ... }:

{
  den.aspects."assistant@dvalin" = {
    includes = with den.aspects.sops; [
      (secret
        {
          name = "gaia/telegram/apiKey";
          path = ".config/telegram/apiKey";
        }
        {
          hjem = { ... }: { };
        }
      )
    ];
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
                  "${pi-loop}/pi-loop/index.ts"
                  "${pi-memory}/pi-memory/index.ts"
                  "${pi-self-compact}/pi-self-compact/index.ts"
                  "${pi-telegram}/pi-telegram/index.ts"
                ];
                pi.coding-agent.rules = ./AGENTS.md;
              }
            ];
          }).package;
        sessionId = "gaia-${builtins.substring 0 12 (builtins.baseNameOf gaiaPi)}";
      in
      {
        sops.templates."pi-telegram.json" = {
          content = builtins.toJSON {
            allowedUserId = 1919581469;
            botToken = config.sops.placeholder."gaia/telegram/apiKey";
          };
          path = "${config.home.homeDirectory}/.pi/agent/telegram.json";
        };

        systemd.services.gaia = {
          after = [ "sops-nix.service" ];
          requires = [ "sops-nix.service" ];
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
            PI_CODING_AGENT_DIR = "${config.home.homeDirectory}/.pi/agent";
            PI_MEMORY_DIR = "${config.home.homeDirectory}/.local/share/gaia/memory";
            PI_MEMORY_EXIT_SUMMARY = "1";
            PI_TELEGRAM_AUTOSTART = "1";
            PI_MEMORY_SNAPSHOT = "stable";
          };
          serviceConfig = {
            ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/tail -f /dev/null | ${gaiaPi}/bin/pi --mode rpc --session-dir %h/.local/state/pi/sessions --session-id ${sessionId} --provider openai --model gpt-5.6-luna'";
            ExecStartPre = [
              "${pkgs.coreutils}/bin/mkdir -p %h/.pi/agent %h/.local/state/pi/sessions"
              "${pkgs.coreutils}/bin/chmod 600 %h/.pi/agent/telegram.json"
            ];
            Restart = "always";
            RestartSec = 5;
            WorkingDirectory = "${config.home.homeDirectory}/.local/share/gaia";
          };
          wantedBy = [ "default.target" ];
        };

      };
  };
}
