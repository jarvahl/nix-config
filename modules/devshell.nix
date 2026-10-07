{ ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        age
        just
        mdsh
        sops
      ];
    };
  };
}
