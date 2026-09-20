{ fetchFromGitHub
, stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  pname = "herdr-worktrunk";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "devashish2203";
    repo = "herdr-worktrunk";
    rev = "4be9bbbaab1dfbecc81b298d30624052d0c432d1";
    hash = "sha256-cbv92AqqY+5hgecGgEp4XqjayfxpO4Afit4YVNUiifo=";
  };

  installPhase = ''
    mkdir -p $out
    cp -r . $out/
    chmod +x $out/*.sh
  '';
}
