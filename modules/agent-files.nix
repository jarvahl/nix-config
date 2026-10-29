{
  checkedPath,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.agent-files.flakeModules.default ];
}
// lib.mkMerge [
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

  }
  {
    agent-files.instructions = ''
      # Project rules

      - This flake is evaluated from the Git tree. After creating, moving, or renaming files that Nix must import, stage the new paths before `nix eval`, `nix flake check`, or `direnv reload` (`git add <path>`). Untracked files are invisible to flake evaluation.
      - Do not stage generated/cache paths like `.direnv/`.
      - Edit Nix declarations, not generated files. Run `nix run .#write-files` to regenerate the flake/lock, documentation, skills, and workflows; after input changes, run it again to use the updated inputs. Stage new generated files before checks. `nix run .#ci` regenerates workflows and runs `act`, not all file generators.
      - Keep Nix attribute keys sorted alphabetically within each attribute set.
      - `import-tree` loads modules recursively; adding a `default.nix` under `modules/**` is enough once the path is tracked by Git.
      - When including Den aspects, prefer `with den.aspects; [ ... ]` for local aspect names, especially names with hyphens like `dynamic-island`. Avoid direct long references unless needed.
      - When including Den batteries, use `with den.batteries; [ ... ]`; put batteries at the end of `includes` in a separate array, e.g. `(with den.aspects; [ ... ]) ++ (with den.batteries; [ ... ])`.
      - Group secret helpers with `(with den.aspects.sops; [ ... ])`. Related secret declarations may live inside an application's callable `includes`; keep `secrets.file` and `secrets.keyFile` settings on the enclosing host/user entity. The SOPS schema handles sources, identities, and user-key provisioning.
      - In modules containing `agent-files` declarations, use a top-level `lib.mkMerge`; keep the `agent-files` declarations in the last attribute set.

      ## Commit rules

      - English.
      - Format: `<aspect>: <title>`.
    '';

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
        This also regenerates the flake and updates its lock before writing files.
        After input changes, run it again so generators use the updated inputs.
        Stage new generated files before running flake checks.

        Use references only when the skill needs larger supporting documentation.

        For concrete repository paths in generated text, take `checkedPath` as a module argument
        and interpolate it with a Nix path, e.g. `''${checkedPath ./home-manager.nix}`.
        It validates the type, existence, and repository boundary during evaluation,
        returning a root-relative string without a Nix store path. Leave glob patterns as text.

        ## Review and cleanup

        - Check examples, helper names, and paths against the current code.
        - Match each skill's description to its actual scope and contents.
        - Route independent tasks to references; keep the entry point focused on when and what to read.
        - Split only when it avoids loading unrelated instructions, not to meet a length limit.
        - Remove duplication and obsolete guidance; check `${checkedPath ../AGENTS.md}` rules for contradictions too.
        - Keep sources near the functionality they document; do not add a new skill for a one-off cleanup.
        - Edit source declarations, regenerate files, inspect the diff, and run `nix flake check --no-build`.
      '';
    };
  }
]
