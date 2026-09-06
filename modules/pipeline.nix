{ inputs, lib, ... }:

let
  dag = inputs.dag.lib { inherit lib; };

  pipeline =
    { pkgs
    , name
    , nodes
    }:
    let
      entries = lib.mapAttrs (_: node: dag.entryAfter (node.needs or [ ]) node) nodes;
      sorted = dag.topoSort entries;
      orderedNodes =
        if sorted ? result
        then map (entry: entry.name) sorted.result
        else builtins.throw "pipeline '${name}' contains a dependency cycle: ${lib.concatStringsSep ", " (map (entry: entry.name) sorted.cycle)}";
      executable = pkgs.writeShellApplication {
        inherit name;
        text = ''
          set -euo pipefail

          ${lib.concatStringsSep " | " (map (nodeName: lib.getExe nodes.${nodeName}.package) orderedNodes)}
        '';
      };
    in
    executable.overrideAttrs (old: {
      passthru = (old.passthru or { }) // {
        inherit nodes;
      };
    });

  trigger =
    { name
    , package
    , at ? null
    , each ? null
    , description ? "Run pipeline ${name}"
    , serviceConfig ? { }
    , timerConfig ? { }
    }:
    let
      schedule =
        if at != null && each != null then
          throw "pipeline trigger '${name}' accepts either 'at' or 'each', not both"
        else if at != null then
          { OnCalendar = "*-*-* ${at}:00"; }
        else if each != null then
          { OnUnitActiveSec = each; }
        else
          throw "pipeline trigger '${name}' requires either 'at' or 'each'";
    in
    {
      systemd.services.${name} = {
        inherit description;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe package;
        } // serviceConfig;
      };

      systemd.timers.${name} = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          Persistent = true;
          Unit = "${name}.service";
        } // schedule // timerConfig;
      };
    };
in
{
  _module.args.pipeline = pipeline;
  _module.args.trigger = trigger;
}
