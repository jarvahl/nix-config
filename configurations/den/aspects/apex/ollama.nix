{ ... }:
{
  den.aspects.apex.nixos = { pkgs, ... }: {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cpu;
      environmentVariables = {
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_QUEUE = "2";
      };
    };
  };
}
