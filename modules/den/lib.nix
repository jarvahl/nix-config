{ den, lib, ... }:
{
  den.lib.callable =
    aspect:
    aspect
    // {
      __functor =
        self: extraAspect:
        builtins.removeAttrs self [
          "__functor"
          "_module"
        ]
        // {
          includes = (self.includes or [ ]) ++ [ extraAspect ];
        };
    };

  flake.tests.callable =
    let
      aspect =
        name:
        den.lib.aspects.types.aspectType.merge
          [ name ]
          [
            {
              file = __curPos.file;
              value = den.lib.callable { includes = [ { nixos.markers = [ name ]; } ]; };
            }
          ];
      parent = aspect "parent";
      child = aspect "child";
      leaf.nixos.markers = [ "leaf" ];
      markers =
        value:
        lib.sort builtins.lessThan
          (lib.evalModules {
            modules = [
              { options.markers = lib.mkOption { type = lib.types.listOf lib.types.str; }; }
              (den.lib.aspects.resolve "nixos" value)
            ];
          }).config.markers;
    in
    {
      testBaseIncludes = {
        expected = [ "parent" ];
        expr = markers parent;
      };
      testExtraIncludes = {
        expected = [
          "leaf"
          "parent"
        ];
        expr = markers (parent leaf);
      };
      testNestedIncludes = {
        expected = [
          "child"
          "leaf"
          "parent"
        ];
        expr = markers (parent {
          includes = [ (child leaf) ];
        });
      };
    };
}
