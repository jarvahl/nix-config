{ ... }:

{
  den.aspects.thinkbook = {
    provides.jarvahl.hjem = { pkgs, workflow, ... }:
      workflow (rec {
        name = "workflow-demo";
        inherit pkgs;

        nodes = {
          fetchInbox.package = pkgs.writeShellApplication {
            name = "${name}-fetch-inbox";

            text = ''
              printf '%s\n' '{"messages":[{"id":"msg-001","sender":"team@example.test","subject":"Project update"},{"id":"msg-002","sender":"alerts@example.test","subject":"Build failed"}]}'
            '';
          };

          splitMessages = {
            package = pkgs.writeShellApplication {
              name = "${name}-split-messages";
              runtimeInputs = [ pkgs.jq ];

              text = ''
                jq -c '.messages[]'
              '';
            };
            needs = [ "fetchInbox" ];
          };

          classifyMessages = {
            package = pkgs.writeShellApplication {
              name = "${name}-classify-messages";
              runtimeInputs = [ pkgs.jq ];

              text = ''
                jq -c '. + {
                  category:
                    if (.subject | ascii_downcase | contains("build"))
                    then "action"
                    else "information"
                    end
                }'
              '';
            };
            needs = [ "splitMessages" ];
          };

          summarizeTriage = {
            package = pkgs.writeShellApplication {
              name = "${name}-summarize-triage";
              runtimeInputs = [ pkgs.jq ];

              text = ''
                jq -s ' {
                  count: length,
                  actionRequired: (map(select(.category == "action")) | length),
                  messages: map({id, sender, subject, category})
                }' > /dev/null
              '';
            };
            needs = [ "classifyMessages" ];
          };
        };

        at = "*-*-* 08:00:00";
      });
  };
}
