{ lib, ... }:
let
  sshMultiplexingDirectory = ".ssh/.multiplexing";
in
lib.mkMerge [
  {
    den.aspects.ssh = {
      provides.to-users.hjem.programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        extraConfig = ''
          Include ~/.ssh/config.d/*
        '';
        settings."*" = {
          AddKeysToAgent = "no";
          Compression = false;
          ControlMaster = "auto";
          ControlPath = "~/${sshMultiplexingDirectory}/%C";
          ControlPersist = "10m";
          ForwardAgent = false;
          HashKnownHosts = false;
          ServerAliveCountMax = 3;
          ServerAliveInterval = 0;
          UserKnownHostsFile = "~/.ssh/known_hosts";
        };
      };

      provides.to-users.hjem.files."${sshMultiplexingDirectory}" = {
        permissions = "0700";
        type = "directory";
      };

      nixos.services.openssh = {
        enable = true;
        ports = [
          22
          2222
        ];
        settings = {
          KbdInteractiveAuthentication = true;
          PasswordAuthentication = true;
          PermitRootLogin = "no";
          X11Forwarding = false;
        };
      };
    };
  }
  {
    den.aspects.ssh.sops.nixos =
      { config, ... }:
      {
        sops.secrets."ssh/key" = {
          group = "root";
          mode = "0600";
          owner = "root";
          path = "/etc/ssh/ssh_host_ed25519_key";
          restartUnits = [ "sshd.service" ];
        };

        services.openssh.hostKeys = [
          {
            path = config.sops.secrets."ssh/key".path;
            type = "ed25519";
          }
        ];
      };
  }
]
