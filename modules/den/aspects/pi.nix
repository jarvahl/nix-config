{ inputs, ... }:

{
  den.aspects.pi = {
    hjem = { pkgs, ... }: {
      packages = [
        (inputs.wrappers.lib.wrapPackage {
          inherit pkgs;

          package = pkgs.pi-coding-agent;
          binName = "pi";

          env = {
            PI_SKIP_VERSION_CHECK = "1";
            PI_TELEMETRY = "0";
          };

          args = [
            "--tui-mode"
            "fullscreen"
          ];
        })
      ];
    };

  };
}
