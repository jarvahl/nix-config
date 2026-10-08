{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config."sops-file";

  ageKeys =
    value:
    lib.unique (
      (map (key: cfg.keys.${key}) value) ++ lib.optional (cfg.recovery_key != null) cfg.recovery_key
    );

  pathRegex =
    value:
    if lib.isPath value then
      "${lib.escapeRegex (lib.removePrefix "${self}/" (toString value))}$"
    else
      value;

  keyGroup = lib.mapAttrs (name: value: if name == "age" then ageKeys value else value);
in
{
  config.perSystem =
    { pkgs, ... }:
    lib.optionalAttrs (cfg.creation_rules != [ ]) {
      files.file.${cfg.path}.source = pkgs.concatText cfg.path [
        (pkgs.writeText "sops-file-header" ''
          # DO-NOT-EDIT. This file was auto-generated from sops-file config.
          # Edit Nix sources and regenerate it.

        '')
        ((pkgs.formats.yaml { }).generate cfg.path {
          creation_rules = map (
            rule:
            rule
            // {
              key_groups = map keyGroup rule.key_groups;
              path_regex = pathRegex rule.path_regex;
            }
          ) cfg.creation_rules;
        })
      ];
    };

  options."sops-file" = {
    creation_rules = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            key_groups = lib.mkOption {
              type = lib.types.listOf (lib.types.attrsOf (lib.types.listOf lib.types.str));
            };

            path_regex = lib.mkOption {
              type = lib.types.oneOf [
                lib.types.path
                lib.types.str
              ];
            };
          };
        }
      );
    };

    keys = lib.mkOption {
      default = { };
      type = lib.types.attrsOf lib.types.str;
    };

    path = lib.mkOption {
      default = ".sops.yaml";
      type = lib.types.str;
    };

    recovery_key = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
    };
  };
}
