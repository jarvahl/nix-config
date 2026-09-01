# ❄️ My Nix Configuration

My dotfiles, mostly NixOS these days.

This is where I keep machine configs, shell/editor bits, and whatever glue helps me get my work done.

## Generate a password hash

Generate a yescrypt password hash for `users.users.<name>.hashedPassword` with:

```console
nix shell nixpkgs#mkpasswd --command mkpasswd --method=yescrypt
```

## Generate SOPS keys

### Host identity

Generate a new random age identity at the path used by `sops-nix`:

```console
sudo install -d -m 0750 -o root -g sops /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt
sudo chown root:sops /var/lib/sops-nix/key.txt
sudo chmod 0440 /var/lib/sops-nix/key.txt
```

Print its public recipient for `.sops.yaml`:

```console
sudo age-keygen -y /var/lib/sops-nix/key.txt
```

### Derived recovery identity

Hosts use their own randomly generated age identities. For disaster recovery,
the development shell provides `age-derived-key`, which deterministically
derives a recovery identity from a passphrase:

```console
nix develop
umask 077
age-derived-key recovery > key.txt
```

Print its public recipient for `.sops.yaml`:

```console
age-keygen -y key.txt
```

Add the resulting `age1...` recipient alongside the normal host recipients:

```yaml
keys:
  - &host-a age1HOSTA...
  - &recovery age1RECOVERY...
creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *host-a
          - *recovery
```

The derived identity is only a recovery escape hatch. Remove `key.txt` after
recording or using it; normal hosts should continue using their own randomly
generated keys.

If a host key is lost, derive the recovery identity into the current directory
and point SOPS at it:

```bash
umask 077
age-derived-key recovery > key.txt
export SOPS_AGE_KEY_FILE="$PWD/key.txt"
```

After decrypting the secrets, generate a new random host identity, replace the
lost host recipient in `.sops.yaml`, and run `sops updatekeys`. Remove
`key.txt` and unset `SOPS_AGE_KEY_FILE` when recovery is complete.
