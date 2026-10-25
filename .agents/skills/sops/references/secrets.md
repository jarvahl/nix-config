<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Declare and consume SOPS secrets

Entity settings in `modules/den/aspects/sops/schema.nix` select each host's
and user's encrypted file and age identity. All hosts and users must set
`secrets.file`; `secrets.keyFile` defaults to `/var/lib/sops-nix/key.txt` for hosts
and `.config/sops/age/key.txt` for users.

The schema uses helpers in `modules/den/aspects/sops/default.nix`:

- `from file` selects the encrypted YAML file.
- `keyFile path` selects the age identity used for decryption.
- `secret params aspect` declares a secret and includes its consuming aspect.
  The second argument is required; use `{ }` when consumption is configured elsewhere.

## User secrets

Set the source on the user entity:

```nix
den.hosts.x86_64-linux.dvalin.users.jarvahl = {
  classes = [ "hjem" ];
  secrets.file = ./user-jarvahl.sops.yaml;
};
```

Declare individual secrets in the user's aspect, such as `jarvahl@dvalin`,
not the host aspect:

```nix
includes = with den.aspects.sops; [
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
Keep shared source and identity settings on the enclosing user entity.
See `modules/den/aspects/dvalin+/default.nix` for OpenClaw and
`modules/den/aspects/github.nix` for wiring a consumer in the second argument.

## Host secrets

Set `den.hosts.<system>.<host>.secrets.file = ./host.sops.yaml` and override
`secrets.keyFile` when the host's age identity is not at the default path.
Declare individual secrets in the host aspect.
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
