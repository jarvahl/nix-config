{ ... }:

{
  den.aspects."assistant@dvalin".hjem =
    { self', ... }:
    {
      packages = [ self'.packages.agent ];
    };
}
