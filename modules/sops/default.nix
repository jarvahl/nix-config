{ inputs, ... }:
{
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

  flake-file.inputs.sops-nix = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:Mic92/sops-nix";
  };

  perSystem = { pkgs, ... }: {
    devShells.sops-recovery = pkgs.mkShell {
      packages = [
        pkgs.age
        pkgs.sops
      ];

      shellHook = ''
        encrypted_key="''${SOPS_RECOVERY_KEY:-$PWD/recovery.agekey.age}"

        if [ ! -f "$encrypted_key" ]; then
          echo "missing recovery key: $encrypted_key" >&2
          echo "set SOPS_RECOVERY_KEY=/path/to/recovery.agekey.age" >&2
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
}
