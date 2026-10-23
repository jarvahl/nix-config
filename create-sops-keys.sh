#!/usr/bin/env bash
set -euo pipefail

: "${SOPS_AGE_KEY_FILE:?Run this inside nix develop .#sops first}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

age-keygen -o "$workdir/terranix.key" >/dev/null 2>&1
recipient="$(age-keygen -y "$workdir/terranix.key")"

{
  echo "recovery: |"
  sed 's/^/  /' "$SOPS_AGE_KEY_FILE"
  echo "terranix: |"
  sed 's/^/  /' "$workdir/terranix.key"
} > "$workdir/keys.yaml"

age -p -a -o sops-keys.age "$workdir/keys.yaml"

echo "Terranix recipient: $recipient"
