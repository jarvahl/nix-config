<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Declare and consume SOPS secrets

Entity settings in `modules/den/aspects/sops/schema.nix` select each host's
and user's encrypted file and age identity. All hosts and users must set
`secrets.file`; `secrets.keyFile` defaults to `/var/lib/sops-nix/key.txt` for hosts
and `.config/sops/age/key.txt` for users.

The schema configures the source, age identity, and user-key provisioning directly.
Select them through entity settings, not application aspects.
Consumer helpers live in `modules/den/aspects/sops/secret.nix` and
`modules/den/aspects/sops/template.nix`:

- `secret params modules` declares a secret for each explicit `nixos`, `hjem`, or
  `homeManager` key. Module functions receive `path` and `placeholder` alongside
  normal module arguments. Plain module attribute sets are also accepted.
  Omit `path` to use SOPS's runtime path.
- `template params modules` declares a native `sops.templates` entry for each class
  and passes `path` to its module function. `content` accepts a string or a function
  receiving `config.sops.placeholder`. Other parameters are native template options.

Consumers are ordinary class modules, not callbacks returning aspects. Include `...`
in module function arguments, as with other Nix modules. Den handles context injection;
helper references are resolved inside the module system. Compose aspects with the
enclosing aspect's `includes`, not inside a consumer. No decrypted value is exposed to Nix.

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
  } { hjem = { }; })
];
```

An empty module declares the secret without configuring a consumer; the class key is required.
Relative secret paths and `secrets.keyFile` resolve against the user's home directory.
The user schema also declares the host-side `users/<user>/age_key` secret that provisions this identity;
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
Consume the injected `path` inside the second argument's `nixos` module;
user consumers belong in `hjem` modules instead.
See the Tailscale secret in `modules/den/aspects/dvalin+/default.nix`.

## Templates and references

Declare secrets separately; templates do not declare their dependencies automatically.
A secret's `placeholder` is for runtime substitution in templates, while `path` is
for applications that read a file:

```nix
includes = with den.aspects.sops; [
  (secret { name = "composio/api_key"; } {
    hjem = { path, ... }: {
      programs.openclaw.environment.COMPOSIO_API_KEY = path;
    };
  })
  (template {
    content = secrets: "COMPOSIO_API_KEY=\"${secrets."composio/api_key"}\"\n";
    mode = "0400";
    name = "composio-environment";
  } {
    hjem = { path, ... }: {
      systemd.services.example.serviceConfig.EnvironmentFile = path;
    };
  })
];
```

The template example is an alternative consumer, not required for OpenClaw.
Templates retain native SOPS path semantics; use an absolute custom `path`.
See `modules/den/aspects/gitlab.nix` for a template consumer.

## Checks and safety

Verify the encrypted file contains the requested name and its recipients match
the intended host/user. Update creation rules through the existing `sopsFile`
declarations; changing a rule alone does not re-encrypt an existing file.
Never put decrypted values in Nix expressions, logs, or the Nix store.
Pass secret paths through the consumer's supported runtime file mechanism.
Placeholder substitution does not escape shell, JSON, or environment-file syntax;
validate the credential's format or encode it for the consumer's parser.

Run `nix flake check --no-build` and evaluate the affected secret path and consumer.
Evaluation cannot verify deployed age keys, decryption, or service startup.
