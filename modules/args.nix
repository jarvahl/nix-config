{ inputs, self, ... }:

{
  _module.args.nixosSystem =
    { modules ? [ ]
    , specialArgs ? { }
    , system ? "x86_64-linux"
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit modules system;
      specialArgs = { inherit inputs self; } // specialArgs;
    };
}
