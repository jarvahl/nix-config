# tmux-flake

Reusable tmux configuration and session persistence as a Hjem module.

## Configuration

Add the Hjem module and configure the `flake` submodule:

```nix
{
  imports = [ inputs.tmux-flake.hjemModules.default ];

  rum.programs.tmux.flake = {
    enable = true;
    mouse.enable = true;
    mode = "vi";

    windows = {
      baseIndex = 1;
      paneBaseIndex = 1;
      renumber = true;
    };

    history.limit = 50000;
    prefix2 = "Home";

    extendedKeys = {
      enable = true;
      format = "csi-u";
    };

    persistence.enable = true;
  };
}
```

The Hjem module writes `~/.config/tmux/tmux.conf`, installs tmux and the
persistence plugins, and creates the user-session services. User lingering remains a
NixOS/user-level setting and is configured by the consuming system.

Run the configured tmux with:

```console
nix run
```

### Extending Tmux with Custom Modules

Personal keybindings and status styling belong in the consuming configuration:

```nix
rum.programs.tmux.flake.initConfig = lib.mkAfter ''
  set -g status on
'';
```

Enable lingering separately at the NixOS/user level when the services must run
without an active login:

```nix
users.users.<name>.linger = true;
```

Disable persistence when only the tmux configuration and package are needed:

```nix
rum.programs.tmux.flake.persistence.enable = false;
```

The configuration is also available through the library API:

```nix
self.lib.tmuxConfigText {
  inherit pkgs;
  modules = [
    { initConfig = "set -g status on"; }
  ];
}
```
