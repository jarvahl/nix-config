{ config, lib, ... }:
let
  cfg = config.just;

  concatLines = lib.concatStringsSep "\n";

  trimTrailingNewlines =
    text: if lib.hasSuffix "\n" text then trimTrailingNewlines (lib.removeSuffix "\n" text) else text;

  indentBody =
    text:
    lib.pipe text [
      (lib.splitString "\n")
      (map (line: if line == "" then "" else "    ${line}"))
      concatLines
    ];

  quoteJustString = value: "'${lib.replaceStrings [ "\\" "'" ] [ "\\\\" "\\'" ] value}'";

  noValueAttributes = [
    "confirm"
    "linux"
    "macos"
    "no-cd"
    "no-exit-message"
    "positional-arguments"
    "private"
    "script"
    "unix"
    "windows"
  ];

  renderAttribute =
    name: value:
    if value == false then
      null
    else if builtins.elem name noValueAttributes then
      if value == true then "[${name}]" else throw "Just attribute `${name}` must be boolean"
    else if name == "group" then
      "[group(${quoteJustString value})]"
    else if name == "extension" then
      "[extension(${quoteJustString value})]"
    else if name == "working-directory" then
      "[working-directory(${quoteJustString value})]"
    else
      throw "Unsupported Just attribute `${name}`";

  renderAttributes =
    attributes:
    lib.pipe attributes [
      (lib.mapAttrsToList renderAttribute)
      (lib.filter (line: line != null))
      concatLines
    ];

  renderArg = arg: arg.name + lib.optionalString (arg.default != null) "=${arg.default}";
  renderForwardedArg = arg: "{{quote(${arg.name})}}";

  renderRecipe =
    name: recipe:
    let
      attrs = renderAttributes recipe.attributes;
      description = lib.optionalString (recipe.description != null) "# ${recipe.description}";
      signature = "${name}${
        lib.optionalString (recipe.args != [ ]) " ${lib.concatMapStringsSep " " renderArg recipe.args}"
      }:";
      body = indentBody recipe.text;
    in
    trimTrailingNewlines (
      concatLines (
        lib.filter (line: line != "") [
          description
          attrs
          signature
          body
        ]
      )
    );

  renderNixRunRecipe =
    name: recipe:
    renderRecipe name (
      recipe
      // {
        text =
          "nix run .#just-${name}"
          +
            lib.optionalString (recipe.args != [ ])
              " -- ${lib.concatMapStringsSep " " renderForwardedArg recipe.args}";
      }
    );

  renderJustfile =
    recipes:
    concatLines (
      [
        "# DO-NOT-EDIT. This file was auto-generated from just config."
        "# Use `nix run .#write-files` to regenerate it."
        ""
      ]
      ++ lib.intersperse "" (
        lib.mapAttrsToList (
          name: recipe:
          if recipe.runtimeInputs == null then renderRecipe name recipe else renderNixRunRecipe name recipe
        ) recipes
      )
    );

  argType = lib.types.submodule {
    options = {
      default = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
      };

      name = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  recipeType = lib.types.submodule {
    options = {
      args = lib.mkOption {
        default = [ ];
        type = lib.types.listOf argType;
      };

      attributes = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.oneOf [
            lib.types.bool
            lib.types.str
          ]
        );
      };

      description = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
      };

      runtimeInputs = lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.functionTo (lib.types.listOf lib.types.package));
      };

      text = lib.mkOption {
        type = lib.types.lines;
      };
    };
  };
in
{
  options.just.recipes = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (lib.types.coercedTo lib.types.str (text: { inherit text; }) recipeType);
  };

  config.perSystem =
    { pkgs, ... }:
    {
      apps = lib.mapAttrs' (
        name: recipe:
        let
          app = pkgs.writeShellApplication {
            name = "just-${name}";
            runtimeInputs = [ pkgs.just ] ++ recipe.runtimeInputs { inherit pkgs; };
            text = ''
              justfile=$(mktemp)
              trap 'rm -f "$justfile"' EXIT
              printf '%s' ${
                lib.escapeShellArg (renderRecipe "__just_file_recipe" (recipe // { attributes = { }; }))
              } > "$justfile"
              exec just --justfile "$justfile" --working-directory "$PWD" __just_file_recipe "$@"
            '';
          };
        in
        lib.nameValuePair "just-${name}" {
          type = "app";
          program = lib.getExe app;
        }
      ) (lib.filterAttrs (_: recipe: recipe.runtimeInputs != null) cfg.recipes);

      files = {
        file."Justfile".text = renderJustfile cfg.recipes;
        writer.app = true;
      };
    };
}
