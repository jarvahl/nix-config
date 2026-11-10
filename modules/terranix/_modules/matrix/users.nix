{ flakeConfig, lib, ... }:
let
  host = flakeConfig.nixosConfigurations.dvalin;
  agents = lib.mergeAttrsList (
    lib.mapAttrsToList (
      _host: nixos: nixos.config.services.matrix.users or { }
    ) flakeConfig.nixosConfigurations
  );
  admins = lib.filterAttrs (
    _: user: user.isNormalUser && builtins.elem "wheel" user.extraGroups
  ) host.config.users.users;
  agentResources = lib.mapAttrs (name: user: {
    avatar_file = toString user.avatar;
    display_name = user.displayName;
    username = name;
  }) agents;
  adminUserResources = lib.mapAttrs (name: _: {
    display_name = name;
    username = name;
  }) admins;
  adminResources = lib.mapAttrs' (
    name: _:
    lib.nameValuePair name {
      depends_on = [ "matrix_user.${name}" ];
      user_id = "@${name}:matrix.tailbf412b.ts.net";
    }
  ) admins;
  userResources = agentResources // adminUserResources;
  passwordOutputs =
    (lib.mapAttrsToList (name: _: {
      name = "sops__dvalin__${name}__matrix__password";
      value = {
        sensitive = true;
        value = "\${matrix_user.${name}.password}";
      };
    }) admins)
    ++ lib.optional (agents ? gaia) {
      name = "sops__dvalin__jarvahl__gaia__matrix__password";
      value = {
        sensitive = true;
        value = "\${matrix_user.gaia.password}";
      };
    };
  userIDOutputs =
    (lib.mapAttrsToList (name: _: {
      name = "sops__dvalin__${name}__matrix__user_id";
      value = {
        sensitive = true;
        value = "\${matrix_user.${name}.user_id}";
      };
    }) admins)
    ++ lib.optional (agents ? gaia) {
      name = "sops__dvalin__jarvahl__gaia__matrix__user_id";
      value = {
        sensitive = true;
        value = "\${matrix_user.gaia.user_id}";
      };
    };
in
{
  output = builtins.listToAttrs (passwordOutputs ++ userIDOutputs);

  provider.matrix = {
    admin_user_id = "@matrix-ops:matrix.tailbf412b.ts.net";
    homeserver_url = "https://matrix.tailbf412b.ts.net";
  };

  resource.matrix_user = userResources;
  resource.matrix_user_admin = adminResources;

  terraform.required_providers.matrix = {
    source = "jarvahl/matrix";
    version = "0.1.0";
  };
}
