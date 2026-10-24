{ checkedPath, lib, ... }:
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
          ${checkedPath ./.}/
          ```

          `import-tree` merges files recursively. Do not manually import sibling aspect files.

          ## Conventions

          Host includes should read declaratively:

          ```nix
          includes = with den.aspects; [
            ssh

            (hyperland hyperland.autologin)
          ];
          ```

          Prefer names that say what happens:

          ```nix
          sops.from
          sops.keyFile
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

          Native Den calls pass that attrset as context for parametric entries.
          The repository's `den.lib.callable` helper instead takes an additional aspect;
          it does not forward the argument as descendant context.

          ## Pattern

          ```nix
          den.aspects.parent = den.lib.callable {
            # base aspect config...
          };
          ```

          Child feature in another file:

          ```nix
          den.aspects.parent.child.nixos = { ... }: {
            # child feature config
          };
          ```

          Pass a single child aspect directly:

          ```nix
          (parent parent.child)
          ```

          To group several aspects, pass an anonymous aspect with `includes`:

          ```nix
          (parent {
            includes = with parent; [
              child
            ];
          })
          ```

          The functor appends `[ extraAspect ]` to the parent's base `includes`, preserving both.
          The argument may also define `nixos` or `hjem` configuration directly.
          Den resolves it as an aspect, not as call parameters.

          Do not implement this with a parametric include that reads `includes` from context:
          nested callable aspects can inherit the parent's list and recursively include themselves.
          Keep normal host/user context resolution in Den's parametric entries.

          An anonymous aspect can group related aspects, such as a service and its SOPS secret.
          `sops.secret params aspect` already accepts a consuming aspect; it returns a plain
          aspect and needs no additional callable wrapper.
          See `${checkedPath ./dvalin+/default.nix}`; the secret stays in the user's context.
          Regression tests live in `flake.tests.callable` in `${checkedPath ../lib.nix}`.
        '';
      };
    };
  }
]
