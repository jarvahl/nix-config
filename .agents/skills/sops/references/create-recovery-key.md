<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Create recovery identity

`breakglass.age` contains one raw age recovery identity, encrypted with a
passphrase. Terranix reuses the SOPS shell's unlocked identity; there is no
separate Terranix identity or YAML key bundle.

Encrypt an existing recovery identity from a private runtime file:

```shell
age -p -a -o breakglass.age "$SOPS_AGE_KEY_FILE"
```

Verify the encrypted identity before removing the plaintext copy or an
older encrypted copy. Never replace the existing recovery identity without
first migrating and verifying every encrypted file that depends on it.

`nix develop .#sops` unlocks it into a private runtime directory. A systemd user service waits for the shell via pidfd
and removes the directory when the shell exits, including after SIGKILL.
Unlocking it grants access to all recovery-protected secrets.
