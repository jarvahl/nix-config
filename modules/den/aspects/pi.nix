{ inputs, ... }:

{
  flake-file.inputs.pi.url = "github:lukasl-dev/pi.nix";

  den.aspects.pi.hjem.programs.pi.coding-agent = {
    enable = true;
    environment = {
      PI_SKIP_VERSION_CHECK.value = "1";
      PI_TELEMETRY.value = "0";
    };
    extraArgs = [
      "--tui-mode"
      "fullscreen"
    ];
  };

  den.default.nixos.hjem.extraModules = [
    inputs.pi.homeModules.default
  ];

  den.default.nixos.nixpkgs.overlays = [
    inputs.pi.overlays.default
  ];
}
