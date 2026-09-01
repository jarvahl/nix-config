{ den, lib, ... }:
{
  den.aspects.titan = lib.mkMerge [
    {
      provides.nixos-user =
        { user, ... }:
        let
          passwordSecret = "users/${user.userName}/hashedPassword";
        in
        {
          nixos =
            { config, ... }:
            {
              sops.secrets.${passwordSecret}.neededForUsers = true;

              users.users.${user.userName}.hashedPasswordFile =
                config.sops.secrets.${passwordSecret}.path;
            };

          includes = [
            den.batteries.primary-user
            (den.batteries.user-shell "zsh")
            den.aspects.development
          ];
        };
    }
    {
      nixos = {
        services.n8n = {
          enable = true;
          openFirewall = false;

          environment = {
            N8N_PORT = "5678";
            N8N_DIAGNOSTICS_ENABLED = "false";
            N8N_SECURE_COOKIE = "false";
            N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
          };
        };
      };

      includes = [
        (den.batteries.unfree [ "n8n" ])
      ];
    }
    {
      nixos = { pkgs, ... }: {
        services.ollama = {
          enable = true;
          package = pkgs.ollama-cpu;

          host = "127.0.0.1";
          port = 11434;

          environmentVariables = {
            OLLAMA_NUM_PARALLEL = "1";
            OLLAMA_MAX_QUEUE = "256";
          };
        };
      };
    }
    {
      nixos = {
        services.open-webui = {
          enable = true;

          host = "0.0.0.0";
          port = 8080;

          environment = {
            OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";

            ENABLE_API_KEYS = "True";

            ANONYMIZED_TELEMETRY = "False";
            DO_NOT_TRACK = "True";
            SCARF_NO_ANALYTICS = "True";
          };
        };

        networking.firewall.allowedTCPPorts = [ 80 ];
      };

      includes = [
        (den.batteries.unfree [ "open-webui" ])
      ];
    }
    {
      nixos.sops.defaultSopsFile = ./secrets.yml;
    }
  ];

  den.hosts.x86_64-linux.titan.users.nixos-user.userName = "nixos";
}
