{ ... }:
{
  den.aspects.git.hjem = { config, lib, ... }: {
    programs.git.enable = true;
    programs.zsh.bundle.git.enable = lib.mkDefault config.programs.git.enable;
    rum.programs.git.settings = {
      format.pretty = "oneline";
      log.decorate = "short";
    };
  };

  den.default.nixos.hjem.extraModules = [
    ({ lib, ... }: {
      imports = [
        (lib.mkAliasOptionModule [ "programs" "git" "enable" ] [ "rum" "programs" "git" "enable" ])
      ];
    })
  ];
}
