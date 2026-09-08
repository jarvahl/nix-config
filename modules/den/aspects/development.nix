{ den, ... }:
{
  den.aspects.development = {
    includes = with den.aspects; [ console direnv gh lazygit ripgrep devbox nvim worktrunk ];
  };
}
