{ den, ... }:

{
  den.aspects."jarvahl@dvalin" = {
    includes = [
      (den.aspects.agent {
        name = "gaia";
        rules = ./AGENTS.md;
        extensions =
          { self', ... }:
          [ "${self'.packages.pi-matrix-synapse}/pi-matrix-synapse/index.ts" ];
        settings = {
          defaultModel = "gpt-6-luna";
          defaultProvider = "openai";
        };
        environment = {
          MATRIX_ALLOWED_INVITE_USERS = "@jarvahl:matrix.tailbf412b.ts.net,@nixos:matrix.tailbf412b.ts.net";
          MATRIX_HOMESERVER = "https://matrix.tailbf412b.ts.net";
        };
        service = {
          after = [ "sops-nix.service" ];
          requires = [ "sops-nix.service" ];
          restartIfChanged = true;
          serviceConfig.TimeoutStopSec = "60s";
        };
      })
      (den.aspects.matrix.user {
        avatar = ./avatar.jpeg;
        displayName = "Gaia · AI";
        name = "gaia";
      })
    ];
  };
}
