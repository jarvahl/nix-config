{ pipeline, trigger, ... }:

{
  den.aspects.thinkbook = {
    provides.jarvahl.hjem = { pkgs, ... }:
      let
        package = pipeline rec {
          name = "pipeline-demo";
          nodes = {
            fetchInbox = {
              package = pkgs.writeShellApplication {
                name = "${name}-fetch-inbox";
                text = ''
                  cat <<'EOF'
                  {"messages":[{"id":"msg-001","sender":"team@example.test","subject":"Project update","body":"The local demo is ready."},{"id":"msg-002","sender":"alerts@example.test","subject":"Build failed","body":"The nightly build needs attention."}]}
                  EOF
                '';
              };
            };

            splitMessages = {
              needs = [ "fetchInbox" ];
              package = pkgs.writeShellApplication {
                name = "${name}-split-messages";
                runtimeInputs = [ pkgs.jq ];
                text = ''
                  jq -c '.messages[]'
                '';
              };
            };

            classifyMessages = {
              needs = [ "splitMessages" ];
              package = pkgs.writeShellApplication {
                name = "${name}-classify-messages";
                runtimeInputs = [ pkgs.jq ];
                text = ''
                  while IFS= read -r message; do
                    jq -c '
                      . + {category: (if (.subject | ascii_downcase | contains("build")) then "action" else "information" end)}
                    ' <<< "$message"
                  done
                '';
              };
            };

            summarizeTriage = {
              needs = [ "classifyMessages" ];
              package = pkgs.writeShellApplication {
                name = "${name}-summarize-triage";
                runtimeInputs = [ pkgs.jq ];
                text = ''
                  jq -s '{count: length, actionRequired: (map(select(.category == "action")) | length), messages: map({id, sender, subject, category})}'
                '';
              };
            };
          };
          inherit pkgs;
        };
      in
      trigger {
        name = "pipeline-demo";
        inherit package;
        description = "Run the local demo pipeline";
        at = "08:00";
      };
  };
}
