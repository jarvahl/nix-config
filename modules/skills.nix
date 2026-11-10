{ config, lib, ... }:
let
  cfg = config.skills;
  inherit (lib)
    concatMapAttrs
    concatStringsSep
    defaultTo
    isFunction
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mkOption
    nameValuePair
    optionalString
    types
    ;

  notice = "<!-- DO-NOT-EDIT. This file was auto-generated using local skills modules. Use nix run .#write-files to regenerate it. -->";
  appName = skill: name: "agent-${skill}-${name}";
  render = value: ctx: if isFunction value then value ctx else value;

  ctx = skill: dir: {
    references = mapAttrs (name: _: "${dir}${name}.md") cfg.${skill}.references;
    scripts = mapAttrs (name: _: "nix run .#${appName skill name}") cfg.${skill}.scripts;
  };

  section =
    title: items: line:
    optionalString (items != { }) ("\n## ${title}\n" + concatStringsSep "" (mapAttrsToList line items));

  opt = default: type: mkOption { inherit default type; };
  nullOr = type: opt null (types.nullOr type);
  submodule = options: types.submodule { inherit options; };
in
{
  options.skills = opt { } (
    types.attrsOf (submodule {
      description = opt "" types.str;
      instructions = opt "" types.unspecified;
      references = opt { } (
        types.attrsOf (submodule {
          description = nullOr types.str;
          source = nullOr types.path;
          text = opt "" types.unspecified;
        })
      );
      scripts = opt { } (
        types.attrsOf (submodule {
          description = nullOr types.str;
          runtimeInputs = opt (_: [ ]) types.unspecified;
          text = mkOption { type = types.lines; };
        })
      );
    })
  );

  config.perSystem =
    { pkgs, ... }:
    {
      apps =
        cfg
        |> concatMapAttrs (
          skill:
          { scripts, ... }:
          scripts
          |> mapAttrs' (
            name: script:
            nameValuePair (appName skill name) {
              type = "app";
              program = lib.getExe (
                pkgs.writeShellApplication {
                  name = appName skill name;
                  runtimeInputs = script.runtimeInputs { inherit pkgs; };
                  inherit (script) text;
                }
              );
              meta.description = defaultTo "Agent script ${name}" script.description;
            }
          )
        );

      files = {
        writer.app = true;
        file =
          cfg
          |> concatMapAttrs (
            skill: s:
            {
              ".agents/skills/${skill}/SKILL.md".text = ''
                ---
                name: ${builtins.toJSON skill}
                description: ${builtins.toJSON s.description}
                ---
                ${notice}

                ${render s.instructions (ctx skill "references/")}
              ''
              + section "References" s.references (
                name: r: "- [${defaultTo name r.description}](references/${name}.md)\n"
              )
              + section "Scripts" s.scripts (
                name: script:
                "- **${name}**${
                  optionalString (script.description != null) " — ${script.description}"
                }\n - `nix run .#${appName skill name}`\n"
              );
            }
            // (
              s.references
              |> mapAttrs' (
                name: r:
                nameValuePair ".agents/skills/${skill}/references/${name}.md" {
                  text =
                    notice
                    + "\n\n"
                    + (if r.source == null then render r.text (ctx skill "") else builtins.readFile r.source);
                }
              )
            )
          );
      };
    };
}
