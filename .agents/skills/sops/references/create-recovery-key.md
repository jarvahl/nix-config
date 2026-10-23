<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Create SOPS key bundle

Store the `recovery` and `terranix` age identities in a YAML bundle:

```yaml
recovery: |
  AGE-SECRET-KEY-...
terranix: |
  AGE-SECRET-KEY-...
```

Encrypt it with a passphrase:

```shell
age -p -a -o sops-keys.age keys.yaml
```

Remove the plaintext bundle after encryption. Select an identity with
`SOPS_KEY_NAME` when entering `nix develop .#sops`.
