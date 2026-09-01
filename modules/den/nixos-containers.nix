{ den, lib, ... }:
let
  inherit (den.lib.policy) provide resolve;

  extendHostSchema =
    { ... }:
    {
      options.nixosContainers = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        defaultText = lib.literalExpression "[ ]";
        description = "Den hosts embedded in this host as NixOS containers.";
      };
    };

  validateGuest =
    parent: guest:
    if !(guest ? name && guest ? system && guest ? class) then
      throw "den: ${parent.name}.nixosContainers entries must be Den hosts"
    else if guest.system != parent.system then
      throw "den: NixOS container ${guest.name} must use the same system as parent ${parent.name}"
    else if guest.name == parent.name then
      throw "den: host ${parent.name} cannot contain itself"
    else if guest.nixosContainers != [ ] then
      throw "den: nested NixOS containers are not supported (${parent.name} -> ${guest.name})"
    else
      guest;

  containerGuestNames =
    hosts:
    let
      names = lib.concatMap
        (
          parent: map (guest: (validateGuest parent guest).name) parent.nixosContainers
        )
        (lib.attrValues hosts);
      duplicates = lib.filter
        (
          name: lib.count (candidate: candidate == name) names > 1
        )
        (lib.unique names);
    in
    if duplicates != [ ] then
      throw "den: NixOS container guests may only have one parent: ${lib.concatStringsSep ", " duplicates}"
    else
      names;
in
{
  den.policies.host-to-nixos-containers =
    { host, ... }:
    map
      (guest: resolve.to "nixos-container-guest" {
        inherit host;
        guest = validateGuest host guest;
      })
      host.nixosContainers;

  den.policies.nixos-container-guest-resolve =
    { host, guest, ... }:
    let
      guestHost = den.hosts.${host.system}.${guest.name};
    in
    [
      (provide {
        class = host.class;
        path = [
          "containers"
          guest.name
        ];
        module = {
          autoStart = true;
          privateNetwork = false;
          config = guestHost.mainModule;
        };
      })
    ];

  den.policies.system-to-standalone-os-outputs =
    { system, ... }:
    let
      hosts = den.hosts.${system} or { };
      embedded = containerGuestNames hosts;
    in
    lib.concatMap
      (
        host:
        lib.optionals (host.intoAttr != [ ] && !(builtins.elem host.name embedded)) [
          (resolve.to "host" { inherit host; })
          (den.lib.policy.instantiate host)
        ]
      )
      (lib.attrValues hosts);

  den.schema.host.includes = [ den.policies.host-to-nixos-containers ];
  den.schema.host.imports = [ extendHostSchema ];
  den.schema.nixos-container-guest.includes = [ den.policies.nixos-container-guest-resolve ];
  den.schema.flake-system = {
    excludes = [ den.policies.system-to-os-outputs ];
    includes = [ den.policies.system-to-standalone-os-outputs ];
  };
}
