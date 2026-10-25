<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Declare and consume SOPS secrets

Use the current helpers in `modules/den/aspects/sops.nix`:

- `from file` selects the encrypted YAML file.
- `keyFile path` selects the age identity used for decryption.
- `secret params aspect` declares a secret and includes its consuming aspect.
  The second argument is required; use `{ }` when consumption is configured elsewhere.

## User secrets

Declare these in the user's aspect, such as `jarvahl@dvalin`, not the host aspect:

```nix
includes = with den.aspects.sops; [
  (from ./user-jarvahl.sops.yaml)
  (keyFile ".config/sops/age/key.txt")
  (secret {
    name = "openclaw/gateway_token";
    path = ".config/openclaw/gateway-token";
  } { })
];
```

Relative paths resolve against the user's home directory. `keyFile` also declares
the host-side `users/<user>/age_key` secret that provisions this identity;
ensure the host's encrypted file contains it.

Related declarations may be nested in an application's callable `includes`.
Keep `from` and `keyFile` in the enclosing user aspect when shared by applications.
See `modules/den/aspects/dvalin+/default.nix` for OpenClaw and
`modules/den/aspects/github.nix` for wiring a consumer in the second argument.

## Host secrets

Declare these in the host aspect with a host SOPS file and an absolute key path.
Use an absolute secret destination; set `owner`, `group`, and `restartUnits`
when the consuming service requires them. The default mode is `0600`.
Consume `config.sops.secrets.<name>.path` inside the second argument's `nixos`
module; user consumers belong in `hjem` modules instead.
See the Tailscale secret in `modules/den/aspects/dvalin+/default.nix`.

## Checks and safety

Verify the encrypted file contains the requested name and its recipients match
the intended host/user. Update creation rules through the existing `sopsFile`
declarations; changing a rule alone does not re-encrypt an existing file.
Never put decrypted values in Nix expressions, logs, or the Nix store.
Pass secret paths through the consumer's supported runtime file mechanism.

Run `nix flake check --no-build` and evaluate the affected secret path and consumer.
Evaluation cannot verify deployed age keys, decryption, or service startup.
