{
  buildNpmPackage,
  makeWrapper,
  nodejs,
}:

buildNpmPackage {
  pname = "telegram";
  version = "0.1.0";

  src = ./.;

  dontNpmInstall = true;
  nativeBuildInputs = [ makeWrapper ];
  npmDepsHash = "sha256-JZ89VyWJ4tVUl4JwRqBeL8WHnb8KuSuOhpVWjz9LHJw=";

  installPhase = ''
    npm prune --omit=dev
    mkdir -p "$out/lib/telegram" "$out/bin"
    cp -r dist node_modules package.json "$out/lib/telegram/"
    makeWrapper ${nodejs}/bin/node "$out/bin/telegram" --add-flags "$out/lib/telegram/dist/main.js"
  '';
}
