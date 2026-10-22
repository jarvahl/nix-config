{ ... }:

{
  den.aspects.fonts.nixos =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs.nerd-fonts; [
        fira-code
        jetbrains-mono
      ];
    };
}
