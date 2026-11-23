# FAQ

## What if I lose a host’s SOPS key?

From the repo on the host I’m recovering, run this in Bash:

```sh
eval "$(nix run .#breakglass)"
nix run .#write-host-key
```

If the host’s configured name differs from its hostname, pass the configured
name:

```sh
nix run .#write-host-key -- HOSTNAME
```

The breakglass key is temporary. Don’t print or commit decrypted keys.
