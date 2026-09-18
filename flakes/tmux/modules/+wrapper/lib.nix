{ config, inputs, lib, ... }:
let
  evalTmuxModules =
    { pkgs
    , modules ? [ ]
    , specialArgs ? { }
    ,
    }:
    lib.evalModules {
      modules = config.tmux.modules ++ modules;
      specialArgs = {
        inherit pkgs inputs;
      } // specialArgs;
    };

  tmuxConfigText =
    { pkgs
    , modules ? [ ]
    , specialArgs ? { }
    ,
    }:
    (evalTmuxModules { inherit pkgs modules specialArgs; }).config.rc;

  tmuxConfiguration =
    { pkgs
    , modules ? [ ]
    , specialArgs ? { }
    ,
    }:
    let
      tmuxConf = pkgs.writeText "tmux.conf" (tmuxConfigText {
        inherit pkgs modules specialArgs;
      });
    in
    pkgs.runCommand "tmux-config" { buildInputs = [ pkgs.makeWrapper ]; } ''
      mkdir -p $out/bin
      makeWrapper ${lib.getExe pkgs.tmux} $out/bin/tmux \
        --add-flags "-f ${tmuxConf}"
    '';
in
{
  flake.lib.evalTmuxModules = evalTmuxModules;
  flake.lib.tmuxConfigText = tmuxConfigText;
  flake.lib.tmuxConfiguration = tmuxConfiguration;
}
