{ den, ... }:
{
  den.aspects.console.includes = with den.aspects; [
    bat
    eza
    fzf
    zoxide
    zsh
  ];
}
