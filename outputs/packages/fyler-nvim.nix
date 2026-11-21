{ fetchFromGitHub, vimPlugins }:

vimPlugins.fyler-nvim.overrideAttrs (
  finalAttrs: _oldAttrs: {
    name = "vimplugin-${finalAttrs.pname}-${finalAttrs.version}";
    src = fetchFromGitHub {
      hash = "sha256-zSqo9RTEvbJwicBHfly3zyy+z4EOk7gYXQmaYnVj368=";
      owner = "FylerOrg";
      repo = "fyler.nvim";
      rev = "e1626ff3815a7ebd15698fd6c6d1188a079993d6";
    };
    version = "2.0.0-unstable-2026-09-23";
  }
)
