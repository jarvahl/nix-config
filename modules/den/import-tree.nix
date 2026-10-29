{ den, lib, ... }:
let
  root = ./aspects;
  hasClassDirectory =
    entries:
    lib.any (name: lib.hasPrefix "_" name && entries.${name} == "directory") (
      builtins.attrNames entries
    );
  directories = lib.filterAttrs (
    name: type: type == "directory" && hasClassDirectory (builtins.readDir (root + "/${name}"))
  ) (builtins.readDir root);
in
{
  den.aspects = lib.mapAttrs (name: _: {
    includes = [ (den.batteries.import-tree (root + "/${name}")) ];
  }) directories;

  flake.tests.discovery = {
    testClassDirectory = {
      expected = true;
      expr = hasClassDirectory {
        _nixos = "directory";
        "default.nix" = "regular";
      };
    };
    testOrdinaryDirectory = {
      expected = false;
      expr = hasClassDirectory { plugins = "directory"; };
    };
    testUnderscoreFile = {
      expected = false;
      expr = hasClassDirectory { "_helper.nix" = "regular"; };
    };
  };
}
