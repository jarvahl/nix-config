{ ... }:
{
  den.aspects.git.hjem = {
    programs.git.enable = true;
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
