{ inputs, ... }:
{
  den.default.nixos =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops.age.keyFile = "/var/lib/sops-nix/key.txt";
      hjem.specialArgs.sops = config.sops;
    };

  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
