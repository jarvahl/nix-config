{ inputs, ... }:
{
  flake-file.inputs.agent-files = {
    url = "github:jarvahl/agent-files";
    inputs = {
      files.follows = "files";
      flake-file.follows = "flake-file";
      flake-parts.follows = "flake-parts";
      import-tree.follows = "import-tree";
      nixpkgs.follows = "nixpkgs";
    };
  };

  imports = [ inputs.agent-files.flakeModules.default ];

  "agent-files".instructions = ''
    # Project rules

    - This flake is evaluated from the Git tree. After creating, moving, or renaming files that Nix must import, stage the new paths before `nix eval`, `nix flake check`, or `direnv reload` (`git add <path>`). Untracked files are invisible to flake evaluation.
    - Do not stage generated/cache paths like `.direnv/`.
    - Keep Nix attribute keys sorted alphabetically within each attribute set.
    - `import-tree` loads modules recursively; adding a `default.nix` under `modules/**` is enough once the path is tracked by Git.
    - When including Den aspects, prefer `with den.aspects; [ ... ]` for local aspect names, especially names with hyphens like `dynamic-island`. Avoid direct long references unless needed.
    - When including Den batteries, use `with den.batteries; [ ... ]`; put batteries at the end of `includes` in a separate array, e.g. `(with den.aspects; [ ... ]) ++ (with den.batteries; [ ... ])`.
    - Keep secret helper includes in their own `(with den.aspects.sops.for-*; [ ... ])` group between the main aspects group and the final batteries group.

    ## Commit rules

    - English.
    - Format: `<aspect>: <title>`.
  '';
}
