{ den, lib, ... }:
let
  homeserver = "https://matrix.tailbf412b.ts.net";
  registerMatrixUser =
    pkgs:
    pkgs.writeShellApplication {
      name = "matrix-register-user";
      runtimeInputs = [ pkgs.python3 ];
      text = ''
        set -euo pipefail
        : "''${MATRIX_HOMESERVER:?Missing homeserver URL}"
        : "''${MATRIX_USERNAME:?Missing username}"
        : "''${MATRIX_PASSWORD:?Missing user password}"
        : "''${MATRIX_REGISTRATION_SHARED_SECRET:?Missing Synapse registration secret}"
        python3 - <<'PY'
        import hashlib
        import hmac
        import json
        import os
        import urllib.error
        import urllib.request

        base = os.environ["MATRIX_HOMESERVER"].rstrip("/")
        endpoint = base + "/_synapse/admin/v1/register"
        with urllib.request.urlopen(endpoint, timeout=30) as response:
            nonce = json.load(response)["nonce"]

        username = os.environ["MATRIX_USERNAME"]
        password = os.environ["MATRIX_PASSWORD"]
        secret = os.environ["MATRIX_REGISTRATION_SHARED_SECRET"].encode()
        admin = os.environ.get("MATRIX_ADMIN", "false").lower() == "true"
        admin_flag = "admin" if admin else "notadmin"
        mac_data = "\0".join((nonce, username, password, admin_flag)).encode()
        mac = hmac.new(secret, mac_data, hashlib.sha1).hexdigest()
        body = json.dumps({
            "nonce": nonce,
            "username": username,
            "password": password,
            "admin": admin,
            "mac": mac,
            "displayname": os.environ.get("MATRIX_DISPLAY_NAME", username),
        }).encode()
        request = urllib.request.Request(endpoint, data=body, headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                json.load(response)
        except urllib.error.HTTPError as error:
            if error.code != 400 or json.loads(error.read()).get("errcode") != "M_USER_IN_USE":
                raise SystemExit(f"Synapse user registration failed with HTTP {error.code}")
            login = urllib.request.Request(
                base + "/_matrix/client/v3/login",
                data=json.dumps({
                    "type": "m.login.password",
                    "user": username,
                    "password": password,
                }).encode(),
                headers={"Content-Type": "application/json"},
            )
            try:
                with urllib.request.urlopen(login, timeout=30) as response:
                    json.load(response)
            except urllib.error.HTTPError:
                raise SystemExit("Matrix user exists, but its password does not match Terranix state")
        PY
      '';
    };
in
{
  den.aspects.matrix = {
    includes = with den.aspects.sops; [
      (secret { name = "matrix/registration_shared_secret"; } { nixos = { }; })
      (template
        {
          content = secrets: ''
            MATRIX_REGISTRATION_SHARED_SECRET="${secrets."matrix/registration_shared_secret"}"
          '';
          mode = "0400";
          name = "matrix-synapse-environment";
          owner = "matrix-synapse";
          restartUnits = [ "matrix-synapse.service" ];
        }
        {
          nixos = { path, ... }: {
            systemd.services.matrix-synapse.serviceConfig.EnvironmentFile = path;
          };
        }
      )
    ];

    nixos =
      { pkgs, ... }:
      {
        services.matrix-synapse = {
          enable = true;
          extraConfigFiles = [ "/run/matrix-synapse/runtime-config.yaml" ];
          settings = {
            database.name = "sqlite3";
            enable_registration = false;
            listeners = [
              {
                bind_addresses = [ "127.0.0.1" ];
                port = 8008;
                resources = [
                  {
                    compress = true;
                    names = [ "client" ];
                  }
                ];
                tls = false;
                type = "http";
                x_forwarded = false;
              }
            ];
            public_baseurl = "https://matrix.tailbf412b.ts.net/";
            report_stats = false;
            server_name = "matrix.tailbf412b.ts.net";
          };
        };

        systemd.services.matrix-synapse = {
          preStart = ''
            ${pkgs.python3}/bin/python3 - <<'PY'
            import json
            import os
            from pathlib import Path

            target = Path("/run/matrix-synapse/runtime-config.yaml")
            target.write_text("registration_shared_secret: " + json.dumps(os.environ["MATRIX_REGISTRATION_SHARED_SECRET"]) + "\n")
            target.chmod(0o400)
            PY
          '';
          serviceConfig.RuntimeDirectory = "matrix-synapse";
          serviceConfig.RuntimeDirectoryMode = "0700";
        };

        services.tailscale.services.matrix = {
          port = 8008;
          servicePort = 443;
        };
      };
  };

  perSystem.terranix.terranixConfigurations.terranix.modules = [
    (
      { flakeConfig, pkgs, ... }:
      let
        users = flakeConfig.nixosConfigurations.dvalin.config.users.users;
        sudoUsers = lib.filterAttrs (
          _: user: user.isNormalUser && builtins.elem "wheel" user.extraGroups
        ) users;
        adminOutputs = lib.foldl' (
          outputs: username:
          outputs
          // {
            "sops__dvalin__${username}__matrix__password" = {
              sensitive = true;
              value = "\${random_password.matrix_admin[\"${username}\"].result}";
            };
            "sops__dvalin__${username}__matrix__user_id" = {
              sensitive = true;
              value = "@${username}:matrix.tailbf412b.ts.net";
            };
          }
        ) { } (builtins.attrNames sudoUsers);
        adminKeys = lib.concatStringsSep ", " (
          map (username: "\"${username}\"") (builtins.attrNames sudoUsers)
        );
      in
      {
        output = {
          sops__dvalin__host__matrix__registration_shared_secret = {
            sensitive = true;
            value = "\${var.MATRIX_REGISTRATION_SHARED_SECRET}";
          };
          sops__dvalin__jarvahl__gaia__matrix__password = {
            sensitive = true;
            value = "\${random_password.matrix_gaia.result}";
          };
          sops__dvalin__jarvahl__gaia__matrix__user_id = {
            sensitive = true;
            value = "@gaia:matrix.tailbf412b.ts.net";
          };
        }
        // adminOutputs;

        resource.random_password = {
          matrix_admin = {
            for_each = "\${toset([${adminKeys}])}";
            length = 48;
            special = false;
          };
          matrix_gaia = {
            length = 48;
            special = false;
          };
        };
        resource.terraform_data = {
          matrix_admin = {
            for_each = "\${var.MATRIX_CREATE_USERS ? toset([${adminKeys}]) : toset([])}";
            input.password = "\${random_password.matrix_admin[each.key].result}";
            provisioner = [
              {
                local-exec = {
                  command = lib.getExe (registerMatrixUser pkgs);
                  environment = {
                    MATRIX_ADMIN = "true";
                    MATRIX_DISPLAY_NAME = "\${each.key}";
                    MATRIX_HOMESERVER = homeserver;
                    MATRIX_PASSWORD = "\${random_password.matrix_admin[each.key].result}";
                    MATRIX_REGISTRATION_SHARED_SECRET = "\${var.MATRIX_REGISTRATION_SHARED_SECRET}";
                    MATRIX_USERNAME = "\${each.key}";
                  };
                };
              }
            ];
            triggers_replace = {
              password = "\${random_password.matrix_admin[each.key].result}";
              username = "\${each.key}";
            };
          };
          matrix_gaia_user = {
            count = "\${var.MATRIX_CREATE_USERS ? 1 : 0}";
            input.password = "\${random_password.matrix_gaia.result}";
            provisioner = [
              {
                local-exec = {
                  command = lib.getExe (registerMatrixUser pkgs);
                  environment = {
                    MATRIX_ADMIN = "false";
                    MATRIX_DISPLAY_NAME = "Gaia";
                    MATRIX_HOMESERVER = homeserver;
                    MATRIX_PASSWORD = "\${random_password.matrix_gaia.result}";
                    MATRIX_REGISTRATION_SHARED_SECRET = "\${var.MATRIX_REGISTRATION_SHARED_SECRET}";
                    MATRIX_USERNAME = "gaia";
                  };
                };
              }
            ];
            triggers_replace = {
              password = "\${random_password.matrix_gaia.result}";
              username = "gaia";
            };
          };
        };

        terraform.required_providers.random.source = "hashicorp/random";
        variable.MATRIX_CREATE_USERS = {
          default = false;
          type = "bool";
        };
        variable.MATRIX_REGISTRATION_SHARED_SECRET = {
          sensitive = true;
          type = "string";
        };
      }
    )
  ];
}
