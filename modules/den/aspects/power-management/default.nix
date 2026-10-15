{ den, ... }:
{
  den.aspects.power-management = {
    includes = [
      (
        {
          includes ? (_: [ ]),
          ...
        }:
        {
          includes = includes (builtins.removeAttrs den.aspects.power-management [ "__functor" ]);
        }
      )
    ];
  };
}
