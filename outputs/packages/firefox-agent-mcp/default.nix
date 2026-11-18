{ pkgs }:

let
  python = pkgs.python3.withPackages (packages: [
    packages.beautifulsoup4
    packages.mcp
  ]);
in
pkgs.writeShellApplication {
  name = "firefox-agent-mcp";
  runtimeInputs = [ python ];

  text = ''
    exec ${python}/bin/python ${./.}/server.py
  '';
}
