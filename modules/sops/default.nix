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

  den.default.nixos =
    { config, ... }:
    {
      hjem.homeManagerModules = [
        inputs.sops-nix.homeManagerModules.sops
      ];
      hjem.specialArgs.sops = config.sops;
      imports = [ inputs.sops-nix.nixosModules.sops ];
      sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    };

  flake-file.inputs = {
    sops-file = {
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
    sops-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/sops-nix";
    };
  };

  imports = [ inputs.sops-file.flakeModules.default ];

  perSystem = { pkgs, ... }: {
    devShells.sops-recovery = pkgs.mkShell {
      packages = [
        pkgs.age
        pkgs.sops
      ];

      shellHook = ''
        encrypted_key="''${SOPS_RECOVERY_KEY:-$PWD/recovery.key.age}"

        if [ ! -f "$encrypted_key" ]; then
          echo "missing recovery key: $encrypted_key" >&2
          echo "set SOPS_RECOVERY_KEY=/path/to/recovery.key.age" >&2
          return 1
        fi

        key="$(mktemp)"
        if ! age -d -o "$key" "$encrypted_key"; then
          rm -f "$key"
          return 1
        fi

        chmod 600 "$key"
        export SOPS_AGE_KEY_FILE="$key"

        cleanup_sops_recovery() {
          rm -f "$SOPS_AGE_KEY_FILE"
        }
        trap cleanup_sops_recovery EXIT

        echo "sops recovery shell active"
        echo "using encrypted key: $encrypted_key"
      '';
    };
  };

  sops-file.keys.recovery = "age17dkg84wglz4nq2523fayp528qr82njr2znlwc6fvdhzy8k3pg3gsusgx2q";
}
