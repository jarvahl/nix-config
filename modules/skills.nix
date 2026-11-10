{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.skills;

  splitPath = path: lib.filter (part: part != "") (lib.splitString "/" path);

  commonPrefixLength =
    left: right:
    if left == [ ] || right == [ ] || builtins.head left != builtins.head right then
      0
    else
      1 + commonPrefixLength (builtins.tail left) (builtins.tail right);

  relativePath =
    fromDir: toPath:
    let
      from = splitPath fromDir;
      to = splitPath toPath;
      common = commonPrefixLength from to;
      ups = lib.replicate ((builtins.length from) - common) "..";
      downs = lib.drop common to;
    in
    lib.concatStringsSep "/" (ups ++ downs);

  escapeYaml = value: lib.replaceStrings [ "\\" "\"" "\n" ] [ "\\\\" "\\\"" "\\n" ] value;

  render = value: context: if lib.isFunction value then value context else value;

  generatedNotice = "<!-- DO-NOT-EDIT. This file was auto-generated using local skills modules. Use nix run .#write-files to regenerate it. -->";

  scriptRecords = lib.flatten (
    lib.mapAttrsToList (
      skillName: skill:
      lib.mapAttrsToList (scriptName: script: {
        inherit
          skillName
          skill
          scriptName
          script
          ;
        appName = "agent-${skillName}-${scriptName}";
      }) skill.scripts
    ) cfg
  );

  skillPath = skillName: ".agents/skills/${skillName}/SKILL.md";
  referencePath =
    skillName: referenceName: ".agents/skills/${skillName}/references/${referenceName}.md";

  referenceContext = skillName: fromDir: {
    references = lib.mapAttrs (
      name: _reference: relativePath fromDir (referencePath skillName name)
    ) cfg.${skillName}.references;
    scripts = lib.mapAttrs (
      name: _script: "nix run .#agent-${skillName}-${name}"
    ) cfg.${skillName}.scripts;
  };

  referencesSection =
    skillName: skill:
    lib.optionalString (skill.autoReferences && skill.references != { }) (
      "\n## References\n"
      + lib.concatStringsSep "" (
        lib.mapAttrsToList (
          name: reference:
          let
            label = if reference.description == null then name else reference.description;
          in
          "- [${label}](${relativePath (builtins.dirOf (skillPath skillName)) (referencePath skillName name)})\n"
        ) skill.references
      )
    );

  scriptsSection =
    skillName: skill:
    lib.optionalString (skill.autoScripts && skill.scripts != { }) (
      "\n## Scripts\n"
      + lib.concatStringsSep "" (
        lib.mapAttrsToList (
          name: script:
          let
            description = lib.optionalString (script.description != null) " — ${script.description}";
          in
          "- **${name}**${description}\n  - `nix run .#agent-${skillName}-${name}`\n"
        ) skill.scripts
      )
    );

  skillMarkdown =
    skillName: skill:
    let
      context = referenceContext skillName (builtins.dirOf (skillPath skillName));
    in
    ''
      ---
      name: "${escapeYaml skillName}"
      description: "${escapeYaml skill.description}"
      ---

      ${generatedNotice}

      ${render skill.instructions context}
    ''
    + referencesSection skillName skill
    + scriptsSection skillName skill;

  skillFiles = lib.listToAttrs (
    lib.mapAttrsToList (skillName: skill: {
      name = skillPath skillName;
      value.text = skillMarkdown skillName skill;
    }) cfg
  );

  referenceFiles = lib.listToAttrs (
    lib.flatten (
      lib.mapAttrsToList (
        skillName: skill:
        lib.mapAttrsToList (
          referenceName: reference:
          let
            context = referenceContext skillName (builtins.dirOf (referencePath skillName referenceName));
          in
          {
            name = referencePath skillName referenceName;
            value =
              if reference.source == null then
                { text = generatedNotice + "\n\n" + render reference.text context; }
              else
                { text = generatedNotice + "\n\n" + builtins.readFile reference.source; };
          }
        ) skill.references
      ) cfg
    )
  );
in
{
  imports = [ "${inputs.files}/flake-module.nix" ];

  options = {
    skills = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            description = lib.mkOption {
              default = "";
              type = lib.types.str;
              description = "Skill description used in YAML frontmatter and references.";
            };

            instructions = lib.mkOption {
              default = "";
              type = lib.types.unspecified;
              description = "Skill instructions, either text or a function receiving { references, scripts }.";
            };

            autoReferences = lib.mkOption {
              default = true;
              type = lib.types.bool;
              description = "Append a References section to SKILL.md.";
            };

            autoScripts = lib.mkOption {
              default = true;
              type = lib.types.bool;
              description = "Append a Scripts section to SKILL.md.";
            };

            references = lib.mkOption {
              default = { };
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    description = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.str;
                      description = "Reference link label.";
                    };

                    text = lib.mkOption {
                      default = "";
                      type = lib.types.unspecified;
                      description = "Reference Markdown, either text or a function receiving { references, scripts }.";
                    };

                    source = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.path;
                      description = "Static source file for this reference.";
                    };
                  };
                }
              );
            };

            scripts = lib.mkOption {
              default = { };
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    description = lib.mkOption {
                      default = null;
                      type = lib.types.nullOr lib.types.str;
                      description = "Script description for SKILL.md.";
                    };

                    runtimeInputs = lib.mkOption {
                      default = _: [ ];
                      type = lib.types.unspecified;
                      description = "Function from { pkgs } to runtime inputs.";
                    };

                    text = lib.mkOption {
                      type = lib.types.lines;
                      description = "Shell application body.";
                    };
                  };
                }
              );
            };
          };
        }
      );
    };
  };

  config = {
    perSystem =
      { pkgs, ... }:
      {
        apps = lib.listToAttrs (
          map (record: {
            name = record.appName;
            value = {
              type = "app";
              program = lib.getExe (
                pkgs.writeShellApplication {
                  name = record.appName;
                  runtimeInputs = record.script.runtimeInputs { inherit pkgs; };
                  text = record.script.text;
                }
              );
              meta.description = record.script.description or "Agent script ${record.scriptName}";
            };
          }) scriptRecords
        );

        files = {
          file = skillFiles // referenceFiles;
          writer.app = true;
        };
      };
  };
}
