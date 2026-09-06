{ lib, ... }:

{
  den.aspects.thinkbook = {
    provides.jarvahl.hjem = { pkgs, ... }:
      let
        package = pkgs.writeShellApplication {
          name = "automation-demo";
          runtimeInputs = [ pkgs.jq ];

          text = ''
            set -euo pipefail

            printf '%s\n' '{"messages":[{"id":"msg-001","sender":"team@example.test","subject":"Project update"},{"id":"msg-002","sender":"alerts@example.test","subject":"Build failed"}]}' |
            jq -c '.messages[]' |
            tee /dev/stderr |
            jq -c '. + {
              category:
                if (.subject | ascii_downcase | contains("build"))
                then "action"
                else "information"
                end
            }' |
            tee /dev/stderr |
            jq -s '{
              count: length,
              actionRequired: (map(select(.category == "action")) | length),
              messages: map({id, sender, subject, category})
            }'
          '';
        };
      in
      {
        systemd.services.automation-demo = {
          description = "Run the local demo automation";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe package;
          };
        };

        systemd.timers.automation-demo = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 08:00:00";
            Persistent = true;
            Unit = "automation-demo.service";
          };
        };
      };
  };
}
