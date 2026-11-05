{ den, ... }:

{
  den.aspects.agent =
    {
      name,
      extensions ? [ ],
      skills ? [ ],
      rules ? null,
      settings ? { },
      environment ? { },
      service ? { },
    }:
    {
      includes = [
        (den.aspects.pi {
          inherit name rules;
          extensions =
            { self', ... }:
            with self'.packages;
            [
              "${pi-browser-use}/pi-browser-use/dist/index.js"
              "${pi-idle-session}/pi-idle-session/index.ts"
              "${pi-loop}/pi-loop/index.ts"
              "${pi-telegram}/pi-telegram/index.ts"
              "${pi-telegram-reply-context}/pi-telegram-reply-context/index.ts"
            ]
            ++ extensions;
          skills =
            { self', ... }:
            with self'.packages;
            [ "${pi-browser-use}/pi-browser-use/skills" ] ++ skills;
          settings =
            { config, pkgs, ... }:
            {
              "pi-browser-use" = {
                executablePath = "${pkgs.chromium}/bin/chromium";
                headed = false;
                mode = "persistent";
                userDataDir = "${config.home.homeDirectory}/.local/share/agents/${name}/browser";
              };
            }
            // settings;
        })
      ];

      hjem =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          dataDirectory = "${config.home.homeDirectory}/.local/share/agents/${name}";
          piServiceScript = pkgs.writeShellScript "${name}-pi-service" ''
            set -euo pipefail

            fifo="$PI_CODING_AGENT_DIR/rpc.stdin"
            /etc/profiles/per-user/${config.user}/bin/pi --mode rpc < "$fifo" &
            pi_pid=$!
            exec 3> "$fifo"

            shutdown() {
              exec 3>&-
              wait "$pi_pid" || true
              exit 0
            }

            trap shutdown TERM INT
            wait "$pi_pid"
          '';
          sessionDirectory = "${dataDirectory}/pi/sessions/--${
            lib.replaceStrings [ "/" ":" ] [ "-" "-" ] (lib.removePrefix "/" dataDirectory)
          }--";
        in
        {
          files.".local/share/agents/${name}/.keep".text = "";

          systemd.services.${name} = lib.mkMerge [
            {
              environment = environment // {
                PI_CODING_AGENT_DIR = "${dataDirectory}/pi";
                PI_MEMORY_DIR = "${dataDirectory}/memory";
                PI_MEMORY_SESSIONS_DIR = sessionDirectory;
                PATH = lib.mkForce (
                  lib.concatStringsSep ":" [
                    "/etc/profiles/per-user/${config.user}/bin"
                    (lib.makeBinPath [
                      pkgs.bash
                      pkgs.coreutils
                      pkgs.curl
                      pkgs.diffutils
                      pkgs.jq
                      pkgs.nodejs
                    ])
                  ]
                );
              };

              serviceConfig = {
                ExecStartPre = [
                  "${pkgs.coreutils}/bin/mkdir -p ${dataDirectory} ${sessionDirectory}"
                  "${pkgs.coreutils}/bin/rm -f ${dataDirectory}/pi/rpc.stdin"
                  "${pkgs.coreutils}/bin/mkfifo -m 600 ${dataDirectory}/pi/rpc.stdin"
                ];
                ExecStart = piServiceScript;
                KillMode = "process";
                Restart = "always";
                RestartSec = 5;
                WorkingDirectory = dataDirectory;
              };
              wantedBy = [ "default.target" ];
            }
            service
          ];
        };
    };
}
