{ inputs, ... }:
{
  flake-file.inputs.hermes-agent = {
    url = "github:NousResearch/hermes-agent";
  };

  den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
    packages = [ inputs.hermes-agent.packages.${pkgs.system}.default ];
  };
}
