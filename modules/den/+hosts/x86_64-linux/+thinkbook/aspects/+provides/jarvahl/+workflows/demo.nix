{ ... }:

{
  den.aspects.thinkbook = {
    provides.jarvahl.hjem = { pkgs, workflow, ... }:
      workflow {
        name = "workflow-demo";
        text = ''
          set -euo pipefail

          printf '%s\n' '{"messages":[{"id":"msg-001","sender":"team@example.test","subject":"Project update"},{"id":"msg-002","sender":"alerts@example.test","subject":"Build failed"}]}' |
            jq -c '.messages[]' |
            jq -c '. + {
              category:
                if (.subject | ascii_downcase | contains("build"))
                then "action"
                else "information"
                end
            }' |
            jq -s ' {
              count: length,
              actionRequired: (map(select(.category == "action")) | length),
              messages: map({id, sender, subject, category})
            }' > /dev/null
        '';
        runtimeInputs = [ pkgs.jq ];
        at = "*-*-* 08:00:00";
        inherit pkgs;
      };
  };
}
