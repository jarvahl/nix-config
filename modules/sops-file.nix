{ inputs, lib, ... }:
{
  _module.args.recovery =
    rules:
    map (
      rule:
      rule
      // {
        key_groups = map (
          group:
          group
          // {
            age = lib.unique (group.age ++ [ "recovery" ]);
          }
        ) rule.key_groups;
      }
    ) rules;

  flake-file.inputs.sops-file = {
    url = "github:jarvahl/sops-file";
    inputs = {
      files.follows = "files";
      flake-file.follows = "flake-file";
      flake-parts.follows = "flake-parts";
      git-hooks-nix.follows = "git-hooks-nix";
      import-tree.follows = "import-tree";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
  };

  imports = [ inputs.sops-file.flakeModules.default ];

  sops-file = {
    creation_rules = [
      {
        key_groups = [
          { age = [ "recovery" ]; }
        ];
        path_regex = ../../secrets-bootstrap.yaml;
      }
    ];

    keys.recovery = "age17dkg84wglz4nq2523fayp528qr82njr2znlwc6fvdhzy8k3pg3gsusgx2q";
  };
}
