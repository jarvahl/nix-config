{ bash, fetchFromGitHub, runCommand }:

let
  src = fetchFromGitHub {
    owner = "onlyjq04";
    repo = "pi-background-jobs";
    rev = "0841bc5a7d8a21cfa68147e5456aac646f05f69b";
    hash = "sha256-j+bPb7Y8HJKd2DgDJWC4Fld/rtK5JOpz0eulBM7iSpg=";
  };
in
runCommand "pi-background-jobs" { } ''
  cp -r --no-preserve=mode,ownership ${src}/. "$out"
  substituteInPlace "$out/src/process-manager.ts" \
    --replace-fail 'spawn("/bin/bash",' 'spawn("${bash}/bin/bash",'
  substituteInPlace "$out/extensions/background-jobs.ts" \
    --replace-fail 'ctrl+b' 'ctrl+shift+b'
''
