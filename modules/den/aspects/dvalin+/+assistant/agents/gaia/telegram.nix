{ den, ... }:

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
        pkgs,
        self',
        ...
      }:
      {
        packages = [ self'.packages.telegram ];

        sops.templates."telegram.env" = {
          content = ''
            TELEGRAM_BOT_TOKEN=${config.sops.placeholder."gaia/telegram/apiKey"}
          '';
          path = "${config.home.homeDirectory}/.config/telegram/telegram.env";
        };

        systemd.services."telegram-for-gaia" = {
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
              "TELEGRAM_AGENT_SOCKET=%t/agents/gaia/gaia.sock"
              "TELEGRAM_CONTROL_SOCKET=%t/agents/telegram-for-gaia/telegram.sock"
              "TELEGRAM_ALLOWED_USER_ID=1919581469"
            ];
            ExecStart = "${self'.packages.telegram}/bin/telegram";
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %t/agents/telegram-for-gaia";
            Restart = "always";
            RestartSec = 5;
          };
          wantedBy = [ "default.target" ];
        };
      };
  };
}
