{ den, ... }:
{
  den.aspects.console.includes = with den.aspects; [
    bat
    eza
    fzf
    rg
    zoxide
    zsh
  ];
}
