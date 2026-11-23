{ inputs, ... }:
{
  den.aspects.herdr.hjem.programs.herdr = {
    enable = true;
    settings = {
      onboarding = false;
      worktrees.directory = "~/.local/share/herdr/worktrees";
    };
  };

  den.default.nixos.hjem.extraModules = [
    (inputs.home-manager + "/modules/programs/herdr.nix")
  ];

}
