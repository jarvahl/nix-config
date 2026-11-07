{ den, ... }:

{
  den.aspects."jarvahl@dvalin" = {
    includes = [
      (den.aspects.agent {
        name = "gaia";
        rules = ./AGENTS.md;
        matrix = true;
        settings = {
          defaultModel = "gpt-6-luna";
          defaultProvider = "openai";
        };
        environment = {
          MATRIX_HOMESERVER = "https://matrix.tailbf412b.ts.net";
          PI_MEMORY_EXIT_SUMMARY = "1";
          PI_MEMORY_EXIT_SUMMARY_TIMEOUT_MS = "30000";
          PI_MEMORY_SNAPSHOT = "stable";
          PI_MEMORY_SUMMARIZE_TRANSITIONS = "1";
        };
        service = {
          after = [ "sops-nix.service" ];
          requires = [ "sops-nix.service" ];
          serviceConfig.TimeoutStopSec = "60s";
        };
      })
    ];
  };
}
