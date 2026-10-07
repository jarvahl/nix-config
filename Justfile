set quiet := true

host := `hostname`

# [build] Build configuration for host
[no-exit-message]
build host=host:
    #!/usr/bin/env bash
    set -euo pipefail

    nixos-rebuild build \
        --flake ".#{{host}}" \
        -L \
        --show-trace \
        --accept-flake-config

# [switch] Apply configuration to host
[no-exit-message]
switch host=host:
    #!/usr/bin/env bash
    set -euo pipefail

    printf '\033[0;32m------------------------\033[0m\n'
    printf '\033[1;32m\uf444 switch \033[0;32m%s\033[0m\n' "{{host}}"
    printf '\033[0;32m------------------------\033[0m\n'

    nixos-rebuild switch \
        --flake ".#{{host}}" \
        --elevate=sudo \
        -L \
        --show-trace \
        --accept-flake-config

    printf '\n'

# [boot] Schedule configuration for next boot
[no-exit-message]
boot host=host:
    #!/usr/bin/env bash
    set -euo pipefail

    nixos-rebuild boot \
        --flake ".#{{host}}" \
        --elevate=sudo \
        -L \
        --accept-flake-config

# [vm] Build and run host in an ephemeral VM
[no-exit-message]
vm host=host:
    #!/usr/bin/env bash
    set -euo pipefail

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    export NIX_DISK_IMAGE="$tmp/disk.qcow2"

    nixos-rebuild build-vm \
        --flake ".#{{host}}" \
        -L \
        --show-trace \
        --accept-flake-config

    "./result/bin/run-{{host}}-vm"

default:
    just --list
