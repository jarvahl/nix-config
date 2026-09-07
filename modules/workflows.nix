{ dag, lib, ... }:
{
  _module.args.workflow =
    { name
    , nodes
    , pkgs
    , at
    ,
    }:
    let
      entries = lib.mapAttrs
        (
          nodeName: node:
            dag.entryAfter (node.needs or [ ]) {
              inherit nodeName;
              inherit (node) package;
            }
        )
        nodes;

      sorted = dag.topoSort entries;

      orderedNodes =
        if sorted ? result then
          sorted.result
        else
          throw "Could not compile workflow '${name}': dependency cycle";

      package = pkgs.writeShellApplication {
        inherit name;

        text = ''
          set -euo pipefail

          ${lib.concatStringsSep " |\n" (map (node: lib.getExe node.data.package) orderedNodes)}
        '';

        passthru.nodes = lib.mapAttrs (_: node: node.package) nodes;
        passthru.at = at;
      };
    in
    {
      systemd.services.${name} = {
        description = "Run the ${name} workflow";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe package;
        };
      };

      systemd.timers.${name} = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = at;
          Persistent = true;
          Unit = "${name}.service";
        };
      };
    };
}
