{ config, lib, self, ... }:
let
  cfg = config."sops-file";

  repoPath = path:
    let
      root = toString self;
      full = toString path;
      prefix = "${root}/";
    in
    if lib.hasPrefix prefix full then
      lib.removePrefix prefix full
    else
      throw "sops-file path_regex must point inside this flake: ${full}";

  renderPathRegex = value:
    if builtins.typeOf value == "path" then
      lib.escapeRegex (repoPath value) + "$"
    else
      value;

  renderKeyGroups = map (group:
    group // lib.optionalAttrs (group ? age) {
      age = map (key: cfg.keys.${key}) group.age;
    });

  rendered = {
    creation_rules = map (rule: rule // {
      key_groups = renderKeyGroups rule.key_groups;
      path_regex = renderPathRegex rule.path_regex;
    }) cfg.creation_rules;
  };
in
{
  config.perSystem = { ... }: lib.optionalAttrs (cfg.creation_rules != [ ]) {
    files.file.${cfg.path}.text = lib.generators.toYAML { } rendered;
  };

  options."sops-file" = {
    creation_rules = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (lib.types.submodule {
        options = {
          key_groups = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf (lib.types.listOf lib.types.str));
          };

          path_regex = lib.mkOption {
            type = lib.types.oneOf [ lib.types.path lib.types.str ];
          };
        };
      });
    };

    keys = lib.mkOption {
      default = { };
      type = lib.types.attrsOf lib.types.str;
    };

    path = lib.mkOption {
      default = ".sops.yml";
      type = lib.types.str;
    };
  };
}
