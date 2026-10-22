{
  config,
  inputs,
  lib,
  recovery,
  ...
}:
let
  servicesByHost = lib.mapAttrs (
    _host: nixos: nixos.config.services.tailscale.services or { }
  ) config.flake.nixosConfigurations;
in
{
  imports = [ inputs.terranix.flakeModule ];

  sopsFile.creation_rules = recovery [
    {
      key_groups = [
        { age = [ "recovery" ]; }
      ];
      path_regex = "secrets\\.yaml$";
    }
    {
      key_groups = [
        { age = [ "recovery" ]; }
      ];
      path_regex = "state\\.sops\\.json$";
    }
  ];

  perSystem =
    { pkgs, ... }:
    {
      terranix.terranixConfigurations.infra = {
        terraformWrapper = {
          package = pkgs.opentofu;
          extraRuntimeInputs = [
            pkgs.age
            pkgs.sops
          ];
          prefixText = ''
            if [ -z "''${SOPS_AGE_KEY_FILE:-}" ]; then
              echo "enter nix develop .#breakglass first" >&2
              exit 1
            fi

            state="$PWD/../state.sops.json"
            secrets="$PWD/../secrets.yaml"

            if [ -f "$state" ]; then
              sops -d "$state" > terraform.tfstate
            fi

            TAILSCALE_API_KEY="$(
              sops -d --extract '["tailscale"]["api_key"]' "$secrets"
            )"
            export TAILSCALE_API_KEY

            cleanup() {
              status="$?"
              if [ -f terraform.tfstate ]; then
                sops --encrypt --filename-override "$state" terraform.tfstate > "$state.tmp"
                mv "$state.tmp" "$state"
                rm -f terraform.tfstate
              fi
              exit "$status"
            }

            trap cleanup EXIT
          '';
        };

        extraArgs.servicesByHost = servicesByHost;
        workdir = ".terranix";

        modules = [
          (
            {
              lib,
              servicesByHost,
              ...
            }:
            let
              services = lib.mergeAttrsList (builtins.attrValues servicesByHost);
            in
            {
              terraform.required_providers.tailscale = {
                source = "tailscale/tailscale";
              };

              resource.tailscale_service = lib.mapAttrs (name: service: {
                name = "svc:${name}";
                ports = [ "tcp:${toString service.port}" ];
                tags = [ "tag:managed" ];
              }) services;
            }
          )
        ];
      };
    };
}
