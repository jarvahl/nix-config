{
  config,
  den,
  inputs,
  lib,
  ...
}:
{
  den.default = lib.mkMerge [
    {
      nixos = with config.flakelight.outputs; {
        imports = lib.attrValues nixosModules;
        nixpkgs.overlays = [ overlays.default ];
      };
    }
    {
      # batteries
      includes = with den.batteries; [
        define-user
        hostname
        inputs'
        primary-user
        self'
      ];
    }
    {
      # default aspects
      includes = with den.aspects; [
        nix
        sops
        sudo
      ];
    }
    {
      nixos.users.mutableUsers = false;
    }
    {
      # core
      nixos = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          jq
          python3
          wget
        ];
      };
    }
    {
      # system version
      nixos.system.stateVersion = lib.mkDefault "25.11";
    }
  ];

  flake-file.inputs.den.url = "github:denful/den";

  imports = [
    inputs.den.flakeModule
  ];

  den.lib.callable =
    aspect:
    aspect
    // {
      # Keep Den's mixed-definition merge from coercing this aspect into a parametric include.
      __functionArgs = {
        config = true;
      };
      __functor =
        self: extraAspect:
        builtins.removeAttrs self [
          "__functionArgs"
          "__functor"
          "_" # Synthetic alias of provides; re-merging both duplicates its definitions.
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
      splitParent =
        den.lib.aspects.types.providerType.merge
          [ "split-parent" ]
          [
            {
              file = "parent.nix";
              value = den.lib.callable { nixos.markers = [ "parent" ]; };
            }
            {
              file = "child.nix";
              value = {
                child.nixos.markers = [ "child" ];
                nixos.markers = [ "extension" ];
              };
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
      testSplitDefinitions = {
        expected = [
          "child"
          "extension"
          "parent"
        ];
        expr = markers (splitParent splitParent.child);
      };
    };
}
