{ den, ... }:

{
  den.aspects."assistant@dvalin".includes = with den.aspects.sops; [
    (secret
      {
        name = "gaia/telegram/apiKey";
        path = ".config/telegram/apiKey";
      }
      {
        hjem = { ... }: { };
      }
    )
  ];
}
