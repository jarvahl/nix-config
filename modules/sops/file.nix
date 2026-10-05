{ inputs, lib, self, config, ... }:
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
      path_regex = renderPathRegex rule.path_regex;
      key_groups = renderKeyGroups rule.key_groups;
    }) cfg.creation_rules;
  };
in
{
  imports = lib.optionals (inputs ? files) [ "${inputs.files}/flake-module.nix" ];

  options."sops-file" = {
    path = lib.mkOption {
      type = lib.types.str;
      default = ".sops.yml";
    };

    keys = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };

    creation_rules = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          path_regex = lib.mkOption {
            type = lib.types.oneOf [ lib.types.path lib.types.str ];
          };

          key_groups = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf (lib.types.listOf lib.types.str));
          };
        };
      });
      default = [ ];
    };
  };

  config = lib.optionalAttrs (inputs ? files) {
    perSystem = { ... }: lib.optionalAttrs (cfg.creation_rules != [ ]) {
      files.file.${cfg.path}.text = lib.generators.toYAML { } rendered;
    };
  };
}
