{ ... }:
{
  zsh.modules = [
    ({ config, lib, ... }:
      let
        renderAlias = name: value: "alias ${name}=${lib.escapeShellArg value}";
        aliasLines = lib.mapAttrsToList renderAlias config.aliases;
        invalidNames = builtins.filter (name: builtins.match "[A-Za-z0-9._+:-]+" name == null) (
          builtins.attrNames config.aliases
        );
      in
      {
        options.aliases = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            ll = "ls -l";
            gs = "git status";
          };
          description = "Simple zsh aliases.";
        };

        config.assertions = [
          {
            assertion = invalidNames == [ ];
            message = "aliases contains invalid alias names: ${lib.concatStringsSep ", " invalidNames}";
          }
        ];

        config.zsh.rc = lib.mkIf (config.aliases != { }) (
          lib.mkOrder 25 (lib.concatStringsSep "\n" aliasLines)
        );
      })
  ];
}
