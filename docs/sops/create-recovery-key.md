# Create SOPS recovery key

Generate age identity:

```shell
age-keygen -o recovery.agekey
```

Encrypt it with a passphrase:

```shell
age -p -a -o recovery.agekey.age recovery.agekey
```

Show public recipient if you later want to add it to SOPS rules:

```shell
age-keygen -y recovery.agekey
```

Remove plaintext identity:

```shell
rm recovery.agekey
```

This creates `recovery.agekey.age`: a passphrase-encrypted age identity safe to keep in the repo.
