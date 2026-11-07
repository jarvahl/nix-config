{ den, lib, ... }:

{
  den.aspects.agent =
    {
      name,
      extensions ? [ ],
      matrix ? false,
      skills ? [ ],
      rules ? null,
      settings ? { },
      environment ? { },
      service ? { },
    }:
    {
      includes = [
        (den.aspects.pi {
          inherit name;
          rules =
            let
              extraRules =
                if rules == null then
                  ""
                else if builtins.isPath rules then
                  builtins.readFile rules
                else
                  rules;
            in
            ''
              Be direct and proportionate. Understand intent; act on straightforward tasks. Ask before destructive, irreversible, or external actions.
              Be honest about uncertainty. Never invent context, completed actions, tool results, or memory changes. Explain decisions plainly and do not expose internal protocols.
              Preserve continuity by recovering relevant context from history or memory when needed, while prioritizing the current user message.
            ''
            + lib.optionalString (extraRules != "") "\n\n${extraRules}";
          extensions =
            { self', ... }:
            with self'.packages;
            [
              "${./agent/pi-idle-new-session.ts}"
              "${pi-browser-use}/pi-browser-use/dist/index.js"
              "${pi-idle-session}/pi-idle-session/index.ts"
              "${pi-loop}/pi-loop/index.ts"
            ]
            ++ lib.optional matrix "${pi-matrix-synapse}/pi-matrix-synapse/index.ts"
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
                headless = false;
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
          browserCleanupScript = pkgs.writeShellScript "${name}-browser-cleanup" ''
            ${pkgs.procps}/bin/pkill -TERM -f -- "--user-data-dir=${dataDirectory}/browser" || true
            sleep 2
            ${pkgs.procps}/bin/pkill -KILL -f -- "--user-data-dir=${dataDirectory}/browser" || true
          '';
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
                  browserCleanupScript
                ];
                ExecStart = "${pkgs.xvfb-run}/bin/xvfb-run -a -s '-screen 0 1280x1024x24' ${piServiceScript}";
                KillMode = "control-group";
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
