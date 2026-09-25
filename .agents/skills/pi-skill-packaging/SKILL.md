---
name: pi-skill-packaging
description: Package and register Agent/Claude-style skills declaratively for Pi in this Nix config.
---

# Packaging Pi skills

Use this when adding external Agent Skills / Claude Skills to Pi in this repository.

## Rules

- Do not run `npx skills add`, `pi install`, or other imperative installers from activation.
- Pin upstream sources with `fetchFromGitHub`.
- Put package definitions under `packages/pi/skills/<name>/package.nix`.
- Flakelight/import-tree exposes them as `pkgs.pi.skills.<name>`.
- Register skills in `programs.pi.skills`.
- Mark new files with `git add -N`.

## Package one skill

```nix
{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "pi-skill-<skill-name>";
  version = "<rev>";

  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "<rev>";
    hash = "<sri>";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/skills
    cp -r skills/<skill-name> $out/skills/<skill-name>
  '';
}
```

Register:

```nix
programs.pi.skills.<skill-name> =
  "${pkgs.pi.skills.<package-name>}/skills/<skill-name>";
```

## Package all skills from a repo

```nix
{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "pi-skills-<repo-name>";
  version = "<rev>";

  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "<rev>";
    hash = "<sri>";
  };

  dontBuild = true;

  installPhase = ''
    cp -r skills $out
  '';
}
```

Register:

```nix
programs.pi.skills.<repo-name> =
  "${pkgs.pi.skills.<repo-name>}/skills";
```

## Package build check

Build only the package file you just added:

```sh
nix build --impure --no-link --expr '
  with import <nixpkgs> { };
  callPackage ./packages/pi/skills/<package-name>/package.nix { }
'
```

Format touched files:

```sh
nix fmt -- packages/pi/skills/<package-name>/package.nix modules/den/aspects/apex/+provides/jarvahl/pi.nix
```
