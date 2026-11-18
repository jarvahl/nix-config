# Local deployment

Use this procedure when deploying the current machine's NixOS configuration.

## Preconditions

Check the worktree:

~~~bash
git status --short
~~~

After creating or moving source files that the flake must import, stage them before evaluation:

~~~bash
git add <source-paths>
~~~

Do not stage generated files, caches, or .direnv/.

## Build

Optionally build the current host without activating it:

~~~bash
just build
~~~

## Switch

Deploy the configuration for the current hostname:

~~~bash
just switch
~~~

The generated Justfile passes the current hostname to nixos-rebuild and uses the repository flake.

Do not edit Justfile directly. It is generated.

## Verification

Treat the deployment as successful only when just switch exits with code 0 and reports that the new configuration was activated.

Warnings about a dirty Git tree are not by themselves deployment failures, but newly created source files must be staged so the flake can see them.
