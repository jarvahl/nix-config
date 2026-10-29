{
  config,
  den,
  lib,
  ...
}:
let
  # Expand import-tree's envelope, leaving recipe paths unevaluated.
  recipeFiles =
    entry:
    if builtins.isPath entry || builtins.isString entry then
      [ entry ]
    else
      let
        value = if lib.isFunction entry then entry { } else entry;
      in
      assert lib.assertMsg (
        builtins.isAttrs value && value ? imports
      ) "pkgs: expected an import-tree of package recipes";
      lib.concatMap recipeFiles value.imports;
  directories =
    modules:
    lib.unique (
      map (
        file:
        let
          path = toString file;
          match = builtins.match "(.*)/_pkgs/.*" path;
        in
        assert lib.assertMsg (match != null) "pkgs: expected a recipe below _pkgs, got ${path}";
        "${builtins.head match}/_pkgs"
      ) (lib.concatMap recipeFiles modules)
    );
  extend =
    prev: packages:
    lib.mapAttrs (
      name: value:
      if builtins.isAttrs value && !lib.isDerivation value then (prev.${name} or { }) // value else value
    ) packages;
  overlay =
    modules: _final: prev:
    extend prev (
      lib.foldl' (
        acc: directory:
        acc
        // extend acc (
          prev.lib.packagesFromDirectoryRecursive {
            callPackage = prev.lib.callPackageWith (prev // { pkgs = prev; });
            inherit directory;
          }
        )
      ) { } (directories modules)
    );
in
{
  den.classes.pkgs.description = "Aspect-local package recipes for the host's nixpkgs overlay";

  den.default.nixos = { host, ... }: {
    nixpkgs.overlays = [ config.flake.pkgsOverlays.${host.name} ];
  };

  den.policies.host-to-pkgs =
    { __entityKind, host, ... }:
    lib.optional (__entityKind == "host") (
      den.lib.policy.instantiate {
        class = "pkgs";
        instantiate = { modules, ... }: overlay modules;
        intoAttr = [
          "pkgsOverlays"
          host.name
        ];
        name = "${host.name}-pkgs";
      }
    );

  den.schema.host.includes = [ den.policies.host-to-pkgs ];

  flake.tests.pkgs = {
    testDuplicateDirectory = {
      expected = [ "/fixture/_pkgs" ];
      expr = directories [
        {
          imports = [
            "/fixture/_pkgs/pi/package.nix"
            "/fixture/_pkgs/pi/extensions/tool/package.nix"
          ];
        }
      ];
    };
    testInvalidRecipePath = {
      expected = false;
      expr = (builtins.tryEval (builtins.deepSeq (directories [ "/fixture/package.nix" ]) true)).success;
    };
    testNamespaceMerge = {
      expected = {
        custom = "custom";
        upstream = "upstream";
      };
      expr = (extend { plugins.upstream = "upstream"; } { plugins.custom = "custom"; }).plugins;
    };
    testPackage = {
      expected = {
        type = "derivation";
      };
      expr = (extend { app.old = true; } { app.type = "derivation"; }).app;
    };
    testSelectedAspect = {
      expected = [ (toString ./aspects/pi/_pkgs) ];
      expr = directories [
        (den.lib.aspects.resolve "pkgs" {
          includes = [ (den.batteries.import-tree ./aspects/pi) ];
        })
      ];
    };
    testUnselectedAspect = {
      expected = [ ];
      expr = directories [ (den.lib.aspects.resolve "pkgs" { includes = [ ]; }) ];
    };
  };
}
