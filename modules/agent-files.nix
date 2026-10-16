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

  agent-files.skills.skill-authoring = {
    description = "Use when defining, organizing, or regenerating repository skills; not for skill-specific domain guidance.";
    instructions = ''
      # Skill authoring

      Declare skills with `agent-files.skills.<name>`.

      A skill may be declared in any imported Nix module, preferably next to the functionality it documents.

      Use:

      - `description` for skill metadata;
      - `instructions` for the generated `SKILL.md` content.

      Write concise descriptions using WHAT, WHEN, and NOT-WHEN:
      what the skill covers, when it should trigger, and when it should not be used.
      Prefer one sentence of roughly 15–25 words.

      Generated skills are written to `.agents/skills/<name>/SKILL.md`.
      Do not edit generated files directly. Regenerate them with `nix run .#write-files`.

      Use references only when the skill needs larger supporting documentation.
    '';
  };

  agent-files.skills.pattern-extraction = {
    description = "Use after non-trivial work to extract reusable patterns and decide between a skill and a reference; not for one-off details.";
    instructions = ''
      # Pattern extraction

      After completing a non-trivial task, identify what is reusable.

      1. Separate general principles from implementation details.
      2. Keep only knowledge likely to be useful again.
      3. Put workflows and rules in a skill.
      4. Put detailed examples and supporting material in references.
      5. Keep project-specific knowledge near the module it describes.
      6. Avoid creating a skill for a one-off observation.

      Describe the result briefly and propose its location before adding it.
    '';
  };

  agent-files.instructions = ''
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
