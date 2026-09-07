{ inputs, lib, ... }:
{
  _module.args.dag = inputs.dag.lib { inherit (inputs.nixpkgs) lib; };

  flake-file.inputs.dag.url = "github:denful/dag";
}
