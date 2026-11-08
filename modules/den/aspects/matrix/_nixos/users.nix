{ lib, ... }:

{
  options.services.matrix.users = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          avatar = lib.mkOption {
            type = lib.types.path;
          };
          displayName = lib.mkOption {
            type = lib.types.str;
          };
          passwordSecret = lib.mkOption {
            default = null;
            type = lib.types.nullOr lib.types.str;
          };

        };
      }
    );
  };
}
