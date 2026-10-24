{ ... }:
{
  den.lib.callable =
    aspect:
    let
      base = builtins.removeAttrs aspect [ "__functor" ];
    in
    base
    // {
      includes = (base.includes or [ ]) ++ [
        (
          {
            includes ? [ ],
            ...
          }:
          {
            inherit includes;
          }
        )
      ];
    };
}
