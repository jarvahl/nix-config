{ lib, ... }:
lib.mkMerge [
  { }
  {
    agent-files.skills.den.references = {
      aspects = {
        description = "Den aspects";
        text = ''
          # Den aspects

          This repo keeps reusable Den behavior under:

          ```text
          modules/den/aspects/
          ```

          `import-tree` merges files recursively. Do not manually import sibling aspect files.

          ## Conventions

          Host includes should read declaratively:

          ```nix
          includes = with den.aspects; [
            ssh

            (hyperland {
              includes = { autologin, ... }: [
                autologin
              ];
            })
          ];
          ```

          Prefer names that say what happens:

          ```nix
          sops.loadSecretsFrom
          sops.decryptWithSshKey
          ssh
          ```

          Avoid vague helpers and compatibility aliases unless there is a real external caller.
        '';
      };

      callable-aspects = {
        description = "Callable aspects";
        text = ''
          # Callable aspects

          ## General rule

          Den aspects can be called with an attrset:

          ```nix
          (aspect { arg = value; })
          ```

          That attrset becomes context for parametric entries inside the aspect, especially functions in `includes`.

          ## Local convention

          When an argument selects extra child aspects from the parent namespace, call it `includes`:

          ```nix
          (parent {
            includes = { child, ... }: [
              child
            ];
          })
          ```

          So `includes` means: “select additional child aspects from this parent namespace”.

          ## Pattern

          ```nix
          den.aspects.parent = {
            includes = [
              ({ includes ? (_: [ ]), ... }: {
                includes = includes (builtins.removeAttrs den.aspects.parent [ "__functor" ]);
              })
            ];

            # base aspect config...
          };
          ```

          Child feature in another file:

          ```nix
          den.aspects.parent.child.nixos = { ... }: {
            # child feature config
          };
          ```

          Host usage:

          ```nix
          (parent {
            includes = { child, ... }: [
              child
            ];
          })
          ```

          ## Flow

          1. Den calls `parent` with `{ includes = ...; }`.
          2. `parent` has a parametric include that receives that attrset.
          3. It calls the selector with `den.aspects.parent`.
          4. The selector returns child aspects to include.

          Use this when child aspects only make sense with the parent.
        '';
      };
    };
  }
]
