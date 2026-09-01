{ fetchFromGitHub, vimUtils }:

vimUtils.buildVimPlugin {
  pname = "filemention.nvim";
  version = "unstable";
  src = fetchFromGitHub {
    owner = "not-manu";
    repo = "filemention.nvim";
    rev = "d8aa9116fa441d0529c53bb5cb2c321f30d9544d";
    hash = "sha256-XeLy1GlSSD3xg5KZWQKJH+riTdcN8e2iIpF7dbGl2MY=";
  };
}
