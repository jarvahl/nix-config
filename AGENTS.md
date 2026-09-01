# Global Instructions

- Before a Nix operation, run `git add <path>` only for newly created, untracked files that the flake needs to see. Modified files that are already tracked are visible to Nix flakes and do not need to be staged again after each change.

- Commit messages: use `scope: short description`, e.g. `terra: add audio support`.
- For host-specific module changes under `modules/config/+machines/<host>/`, use the host as the scope and include the module in the title as `host: module -> title`, e.g. `terra: niri -> extract config`.

## Den File & Aspect Structure Ordering

To keep configuration files consistent, follow this standardized order of keys/attributes:

### 1. File-Level Attribute Ordering

Within a `.nix` configuration file, order the top-level attributes as follows:

1. **Aspect Definition (`den.aspects.<name>`)**: Defines the feature/aspect; always at the top.
2. **Policies (`den.policies.<name>`)**: Relations/routing between entities.
3. **Schema Registrations (`den.schema.<type>.includes`)**: Wiring into the Den schema (e.g., custom class forwarders).
4. **Target Extensions (`den.default.<target>.extraModules`)**: Auxiliary options and configurations.
5. **Flake Source Declarations (`flake-file.inputs.<name>.url`)**: External input definitions at the very bottom.

### 2. Inner-Aspect Attribute Ordering

Within a `den.aspects.<name> = { ... }` block, order attributes as follows:

1. **Sub-aspects and Provisions (`provides` / `_`)**: Declared first to highlight exposed sub-capabilities.
2. **Custom / Application Classes (`zsh`, `tmux`, `nvim`, etc.)**: App-level configuration.
3. **User-level Classes (`hjem`, `homeManager`)**: Configurations targeted at the user environments.
4. **System-level Classes (`nixos`, `darwin`)**: Configurations targeted at OS levels.
5. **Auxiliary Account Classes (`user`)**: Base system user settings.
6. **Composition / Includes (`includes`)**: Aspect dependencies, listed at the end.

### 3. Provides Attribute Style

When an aspect has any `provides` entries, declare `provides` as a nested key inside the `den.aspects.<name> = { ... }` block, even if there is only one provision.

Host-specific guest container provisions belong in the host's `default.nix`, not in a separate sibling file named after the guest. Use `lib.mkMerge` for the host file, and keep both the `provides.<guest>.container` entry and the matching `den.hosts.<system>.<host>.guests.<guest>` declaration in the final merge block at the end of the host `default.nix`.

When consolidating multiple fragments of a host aspect, attach `lib.mkMerge` directly to `den.aspects.<host>`. Always place merge blocks containing `provides` before blocks containing other aspect classes or settings. Keep `den.hosts.<system>.<host>` declarations outside that aspect-level merge.

Host-level catch-all user routing such as `to-users` is a provision. In host trees, declare it under the host aspect's provisions, e.g. `den.aspects.<host>.provides.to-users = { ... };`, while keeping matching files at the host level rather than under `+provides`.

Do not write provisions with chained top-level assignments such as:

```nix
den.aspects.terra.provides.jarvahl.nixos = { ... };
```

Prefer:

```nix
den.aspects.terra = {
  provides.jarvahl.nixos = { ... };
};
```

### 4. Inline Plugin Package Definitions

For plugin-oriented aspects such as `zsh` and `tmux`, keep package fetches/builds inline with the plugin declaration that uses them. Do not hoist plugin packages into a shared outer `let` unless the same derivation is intentionally reused by multiple plugin entries or non-plugin settings.

### 5. Simple Console Tool Aspects

For simple console tool aspects that only install a package and add shell aliases or hooks, prefer direct `hjem.packages` plus `zsh.initConfig`. Do not create a custom `rum.programs.<tool>` module or `den.default.nixos.hjem.extraModules` block unless the tool needs reusable options, conditional behavior, or non-trivial integration logic.

### 6. Neovim Language Grouping

When a host-specific `nvim` class configures language tooling, split related settings with `lib.mkMerge` into domain groups that match that host's role, such as `frontend` and `backend` for a development workstation. Keep LSP presets, server overrides, and language declarations in the same domain block when they belong to the same host-specific toolchain.

## Quickshell OSD Design and Transitions

Keep the Hyprland Quickshell OSD visually and behaviorally inspired by the iPhone Dynamic Island:

- Use a near-black pill with fully rounded ends and a subtle translucent edge highlight. Keep the surface clean and do not add a drop shadow unless explicitly requested.
- Keep icons, clock text, slider tracks, and slider fills in a restrained cool-neutral palette. Avoid bright accent colors and flat medium-gray surfaces unless explicitly requested.
- Treat idle, volume, and brightness as distinct modes. Transitions must be state-aware rather than using one generic animation for every component swap.
- For `idle -> active`, fade out the idle content first, expand the pill, and only then fade in the active component.
- For `active -> idle`, fade out the active component first, shrink the pill, and only then fade in the idle content.
- For `volume <-> brightness`, preserve the pill size and use a short content crossfade; do not collapse through the idle state.
- Repeated events for the currently active mode should restart its hide timeout and animate only the changing slider value, without replaying the whole mode transition.
- Animate slider fills smoothly and clip all content to the pill radius so fills and loaders cannot draw rectangular artifacts outside the island.
- Stop or supersede in-progress transitions when a new mode event arrives so rapid media-key input does not queue or overlap animations.
