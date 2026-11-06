{ den, ... }:

{
  den.aspects."assistant@dvalin" = {
    includes = [
      (den.aspects.agent {
        name = "gaia";
        rules = ./AGENTS.md;
        settings = {
          defaultModel = "gpt-6-luna";
          defaultProvider = "openai";
        };
        environment = {
          PI_MEMORY_EXIT_SUMMARY = "1";
          PI_MEMORY_EXIT_SUMMARY_TIMEOUT_MS = "30000";
          PI_MEMORY_SNAPSHOT = "stable";
          PI_MEMORY_SUMMARIZE_TRANSITIONS = "1";
          TELEGRAM_ALLOWED_USER_IDS = "1919581469";
          TELEGRAM_CHAT_ID = "1919581469";
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
