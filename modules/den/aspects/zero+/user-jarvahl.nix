{ den, recovery, ... }:
let
  host = "zero";
  user = "jarvahl";
in
{
  den = {
    aspects."${user}@${host}" = {
      hjem.files.".ssh/config.d/dvalin".text = ''
        Host dvalin
          HostName dvalin.tailbf412b.ts.net
          User jarvahl
          IdentityFile ~/.ssh/id_ed25519
          IdentitiesOnly yes
      '';

      includes =
        (with den.aspects; [
          # ui
          foot
          (hyperland hyperland.autologin)
          hypridle
          linger
          quickshell
          swaybg
        ])
        ++ (with den.aspects; [
          # tools
          clipboard
          console
          development
          herdr
          (pi {
            extensions =
              { self', ... }:
              with self'.packages;
              [
                "${pi-diff-review}/pi-diff-review/index.ts"
                "${pi-prompt-timer}/pi-prompt-timer/index.ts"
                "${pi-ponytail}/pi-ponytail/index.js"
              ];
          })
        ])
        ++ (with den.aspects; [
          # accounts
          gh
        ])
        ++ (with den.batteries; [
          # batteries
          (user-shell "zsh")
        ]);

      provides.to-hosts =
        with den.aspects.sops;
        secret
          {
            mode = "0400";
            name = "users/${user}/hashed_password";
          }
          {
            nixos = { lib, path, ... }: {
              sops.secrets."users/${user}/hashed_password".neededForUsers = true;
              users.users.${user} = {
                hashedPasswordFile = path;
                initialPassword = lib.mkForce null;
              };
            };
          };
    };

    hosts.x86_64-linux.${host}.users.${user} = {
      classes = [ "hjem" ];
      secrets.file = ./user-${user}.sops.yaml;
    };
  };

  sopsFile = {
    creation_rules = recovery [
      {
        key_groups = [
          { age = [ "${user}@${host}" ]; }
        ];
        path_regex = ./user-${user}.sops.yaml;
      }
    ];

    keys."${user}@${host}" = "age1gfhnnsfzf839uvyr3nf6r3cl85zk4hvewkjpfpncxe8y7dxraeeqyr4y82";
  };
}
