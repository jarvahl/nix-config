{ den, inputs, ... }:
{
  flake-file.inputs.nix-openclaw.url = "github:openclaw/nix-openclaw";

  den.aspects.openclaw = {
    includes = [
      (
        {
          includes ? (_: [ ]),
          ...
        }:
        {
          includes = includes (builtins.removeAttrs den.aspects.openclaw [ "__functor" ]);
        }
      )
    ];

    hjem =
      { config, lib, ... }:
      {
        options.programs.git.enable = lib.mkOption {
          default = false;
          internal = true;
          type = lib.types.bool;
        };

        config.programs.openclaw = {
          config.gateway = {
            auth = {
              mode = "token";
              token = {
                id = "OPENCLAW_GATEWAY_TOKEN";
                provider = "default";
                source = "env";
              };
            };
            bind = "loopback";
            mode = "local";
          };
          enable = true;
          environment.OPENCLAW_GATEWAY_TOKEN = config.sops.secrets."openclaw/gateway_token".path;
        };
      };

    nixos.nixpkgs.config.permittedInsecurePackages = [
      "openclaw-2026.6.33"
    ];
  };

  den.default.nixos.hjem.extraModules = [
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];
}
