{ lib, ... }:
{
  den.aspects.apex.provides.jarvahl.hjem = {
    rum.programs.zsh.initConfig = lib.mkAfter ''
      export EZA_COLORS="di=1;38;2;51;177;255:ex=1;38;2;66;190;101:fi=38;2;242;244;248:ln=38;2;61;219;217:or=38;2;238;83;150:ur=38;2;255;126;182:uw=38;2;255;233;123:ux=38;2;66;190;101:gr=38;2;120;169;255:gw=38;2;255;233;123:gx=38;2;66;190;101:tr=38;2;238;83;150:tw=38;2;255;233;123:tx=38;2;66;190;101:*.nix=38;2;61;219;217:*.md=38;2;120;169;255:*.json=38;2;255;233;123:*.toml=38;2;61;219;217:*.kdl=38;2;61;219;217"

      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#525252"
      zstyle ':fzf-tab:*' fzf-flags --color=fg:#f2f4f8,bg:#161616,hl:#3ddbd9,fg+:#ffffff,bg+:#262626,hl+:#78a9ff,prompt:#3ddbd9,pointer:#ee5396,marker:#42be65,spinner:#3ddbd9,header:#525252

      PROMPT=$'%B%{\e[38;2;61;219;217m%}#%{\e[0m%}%b '
    '';
  };
}
