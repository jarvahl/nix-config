{ den, lib, ... }:
lib.mkMerge [
  {
    den.aspects.cargo.includes = with den.aspects; [
      wsl
      zscaler
    ];
  }
]
