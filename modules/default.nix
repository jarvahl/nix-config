{ inputs, lib, ... }:
{
  imports = with inputs.flake-file.flakeModules; [
    auto-follow
    default
    import-tree
  ];
}
// lib.mkMerge [
  {
    flake-file.inputs = {
      flake-file.url = "github:denful/flake-file";
      flake-parts.url = "github:hercules-ci/flake-parts";
      nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
      terranix.url = "github:terranix/terranix";
    };

    readme-file.title = "nix-config";
    systems = inputs.nixpkgs.lib.systems.flakeExposed;
  }
  (
    let
      root = toString inputs.self.outPath;
      checkedPath =
        path:
        assert lib.assertMsg (builtins.isPath path) "checkedPath: expected a Nix path";
        let
          target = toString path;
        in
        assert lib.assertMsg (
          target == root || lib.hasPrefix "${root}/" target
        ) "checkedPath: path must be inside this repository";
        assert lib.assertMsg (builtins.pathExists path) "checkedPath: path does not exist: ${target}";
        if target == root then "." else lib.removePrefix "${root}/" target;
    in
    {
      _module.args.checkedPath = checkedPath;

      flake.tests.checkedPath = {
        testFile = {
          expected = "modules/default.nix";
          expr = checkedPath ./default.nix;
        };
        testString = {
          expected = false;
          expr = (builtins.tryEval (checkedPath "modules/default.nix")).success;
        };
      };
    }
  )
]
