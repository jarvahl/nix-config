{ den, inputs, ... }:

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

    nixos.nixpkgs.overlays = [
      inputs.pi.overlays.default
    ];
  };

  flake-file.inputs = {
    pi.url = "github:lukasl-dev/pi.nix";
    wrappers.url = "github:lassulus/wrappers";
  };
}
