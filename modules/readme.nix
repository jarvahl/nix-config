{ config, lib, ... }:
let
  cfg = config.readme;
  sectionType = lib.types.submodule {
    options = {
      content = lib.mkOption {
        default = "";
        type = lib.types.lines;
      };

      level = lib.mkOption {
        default = 2;
        type = lib.types.ints.positive;
      };

      order = lib.mkOption {
        default = 500;
        type = lib.types.int;
      };
    };
  };

  renderSection =
    title: section:
    "${lib.concatStringsSep "" (lib.replicate section.level "#")} ${title}\n\n${section.content}";
in
{
  options.readme = lib.mkOption {
    default = { };
    type = lib.types.attrsOf sectionType;
  };

  config = {
    _module.args.mkReadmeSection = order: content: {
      inherit order content;
      level = if order == 0 then 1 else 2;
    };

    perSystem =
      { ... }:
      {
        files = {
          file."README.md".text =
            "<!-- DO-NOT-EDIT. This file was auto-generated from readme config. Use nix run .#write-files to regenerate it. -->\n\n"
            + lib.removeSuffix "\n" (
              cfg
              |> lib.mapAttrsToList (
                title: section: {
                  inherit title;
                  inherit (section) order content level;
                }
              )
              |> lib.sort (left: right: left.order < right.order)
              |> map (section: renderSection section.title section)
              |> lib.concatStringsSep "\n\n"
            )
            + "\n";
          writer.app = true;
        };
      };
  };
}
