{ lib, ... }:
{
  _module.args.workflow =
    { name
    , text
    , runtimeInputs ? [ ]
    , at
    , pkgs
    ,
    }:
    let
      unitName = "workflow-${name}";
      package = pkgs.writeShellApplication {
        name = unitName;
        inherit text runtimeInputs;
        passthru.at = at;
      };
    in
    {
      systemd.services.${unitName} = {
        description = "Run the ${name} workflow";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe package;
        };
      };

      systemd.timers.${unitName} = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = at;
          Persistent = true;
          Unit = "${unitName}.service";
        };
      };
    };
}
