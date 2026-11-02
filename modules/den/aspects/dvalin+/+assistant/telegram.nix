{ den, ... }:

{
  den.aspects."assistant@dvalin" = {
    includes = with den.aspects.sops; [
      (secret
        {
          name = "telegram/bot_token";
          path = ".config/telegram/bot-token";
        }
        {
          hjem = { ... }: { };
        }
      )
    ];

    hjem =
      { config, self', ... }:
      {
        packages = [ self'.packages.telegram ];

        sops.templates."telegram.env" = {
          content = ''
            TELEGRAM_BOT_TOKEN=${config.sops.placeholder."telegram/bot_token"}
          '';
          path = "${config.home.homeDirectory}/.config/telegram/telegram.env";
        };

        systemd.services.telegram = {
          after = [
            "gaia.service"
            "sops-nix.service"
          ];
          requires = [
            "gaia.service"
            "sops-nix.service"
          ];
          serviceConfig = {
            EnvironmentFile = config.sops.templates."telegram.env".path;
            Environment = [
              "TELEGRAM_AGENT_SOCKET=%t/agents/gaia.sock"
              "TELEGRAM_ALLOWED_USER_ID=1919581469"
            ];
            ExecStart = "${self'.packages.telegram}/bin/telegram";
            Restart = "always";
            RestartSec = 5;
          };
          wantedBy = [ "default.target" ];
        };
      };
  };
}
