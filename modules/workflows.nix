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
      package = pkgs.writeShellApplication {
        inherit name text runtimeInputs;
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
