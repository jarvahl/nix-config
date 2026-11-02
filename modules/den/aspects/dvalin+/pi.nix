{ den, ... }:

{
  den.aspects."assistant@dvalin" = {
    includes = with den.aspects.sops; [
      (secret
        {
          name = "telegram/bot_token";
          path = ".config/pi-gateway/telegram-bot-token";
        }
        {
          hjem = { ... }: { };
        }
      )
    ];

    hjem =
      { config, pkgs, ... }:
      {
        files = {
          ".local/share/gaia/AGENTS.md".text = ''
            # GAIA

            You are GAIA, the personal assistant. Keep changes small, explain risky actions,
            and ask before deleting data or sending external messages.
          '';
          ".config/pi-gateway/gaia.yaml".text = ''
            instanceName: gaia
            databasePath: ~/.local/state/pi-gateway/gateway.sqlite3
            logLevel: INFO

            telegram:
              botToken: env:TELEGRAM_BOT_TOKEN
              allowedUserIds:
                - 1919581469
              allowGroups: false

            pi:
              command: /etc/profiles/per-user/assistant/bin/pi
              cwd: ~/.local/share/gaia
              defaultProvider: openai
              defaultModel: gpt-5.6-luna
              sessionDir: ~/.local/state/pi/sessions
              idleTtlSeconds: 1800
              rpcStreamLimit: 16777216
              extraArgs: []
          '';
        };

        sops.templates."pi-gateway.env" = {
          content = ''
            TELEGRAM_BOT_TOKEN=${config.sops.placeholder."telegram/bot_token"}
          '';
          path = "${config.home.homeDirectory}/.config/pi-gateway/gaia.env";
        };

        systemd.services.pi-gateway = {
          after = [ "sops-nix.service" ];
          requires = [ "sops-nix.service" ];
          serviceConfig = {
            EnvironmentFile = config.sops.templates."pi-gateway.env".path;
            ExecStart = "${pkgs.pi-gateway}/bin/pi-gateway run -c ${config.home.homeDirectory}/.config/pi-gateway/gaia.yaml";
            Restart = "always";
            RestartSec = 5;
            WorkingDirectory = "${config.home.homeDirectory}/.local/share/gaia";
          };
          wantedBy = [ "default.target" ];
        };
      };
  };
}
