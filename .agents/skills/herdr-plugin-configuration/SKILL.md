---
name: herdr-plugin-configuration
description: Configure Herdr plugins declaratively through Hjem.
---

# Configuring Herdr plugins

- Add the plugin package to the Hjem `packages` list when the program is enabled.
- Link the immutable plugin tree declaratively at `.local/state/herdr/plugins/<plugin-id>` using `files.<path>.source`.
- Put mutable/user configuration at `.config/herdr/plugins/config/<plugin-id>/config.toml`, not inside the Nix store or plugin tree.
- Put global plugin actions and keybindings in `.config/herdr/config.toml` using the plugin action ID.
- Do not add systemd installers, activation scripts, or imperative `herdr plugin link/install` commands; Hjem owns the files and paths.
- Evaluate the host configuration after adding the plugin and verify the plugin manifest, action IDs, and config directory match.
