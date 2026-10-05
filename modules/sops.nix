{ inputs, ... }:
{
  den.default.nixos =
    { config, ... }:
    {
      hjem.specialArgs.sops = config.sops;
      imports = [ inputs.sops-nix.nixosModules.sops ];
      sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    };

  flake-file.inputs.sops-nix = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:Mic92/sops-nix";
  };
}
