{ lib, ... }:
lib.mkMerge [
  {
    den.aspects.matrix = {
      user.__functor =
        _self:
        {
          avatar,
          displayName,
          name,
          passwordSecret ? "${name}/matrix/password",
        }:
        {
          hjem =
            { config, ... }:
            {
              sops.secrets.${passwordSecret} = { };
              sops.secrets."${name}/matrix/user_id" = { };

              sops.templates."${name}-matrix-environment" = {
                content = ''
                  MATRIX_PASSWORD="${config.sops.placeholder.${passwordSecret}}"
                  MATRIX_USER_ID="${config.sops.placeholder."${name}/matrix/user_id"}"
                '';
                mode = "0400";
              };

              systemd.services.${name}.serviceConfig.EnvironmentFile =
                config.sops.templates."${name}-matrix-environment".path;
            };
          nixos.services.matrix.users.${name} = {
            inherit avatar displayName passwordSecret;
          };
        };
    };
  }
  {
    den.aspects.matrix.sops.nixos =
      { config, ... }:
      {
        sops.secrets."matrix/admin_password" = { };
        sops.secrets."matrix/registration_shared_secret" = { };

        sops.templates.matrix-synapse-environment = {
          content = ''
            MATRIX_REGISTRATION_SHARED_SECRET="${config.sops.placeholder."matrix/registration_shared_secret"}"
          '';
          mode = "0400";
          name = "matrix-synapse-environment";
          owner = "matrix-synapse";
          restartUnits = [ "matrix-synapse.service" ];
        };

        systemd.services.matrix-synapse.serviceConfig.EnvironmentFile =
          config.sops.templates.matrix-synapse-environment.path;
      };
  }
  {
    den.aspects.matrix.nixos =
      { config, pkgs, ... }:
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
            rc_login = {
              account = {
                burst_count = 100.0;
                per_second = 1.0;
              };
              address = {
                burst_count = 100.0;
                per_second = 1.0;
              };
              failed_attempts = {
                burst_count = 20.0;
                per_second = 0.1;
              };
            };
            report_stats = false;
            server_name = "matrix.tailbf412b.ts.net";
            user_directory.search_all_users = true;
          };
        };

        systemd.services.matrix-bootstrap-matrix-ops = {
          after = [ "matrix-synapse.service" ];
          requires = [ "matrix-synapse.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          script = ''
            marker=/var/lib/matrix-synapse/matrix-ops-bootstrap.done
            if [ -e "$marker" ]; then
              exit 0
            fi
            ${config.services.matrix-synapse.package}/bin/register_new_matrix_user \
              -u matrix-ops \
              --password-file ${config.sops.secrets."matrix/admin_password".path} \
              --admin \
              -c ${config.services.matrix-synapse.configFile} \
              -c /run/matrix-synapse/runtime-config.yaml \
              http://127.0.0.1:8008
            install -D -m 0600 /dev/null "$marker"
          '';
        };

        systemd.services.matrix-synapse = {
          preStart = ''
            ${pkgs.python3}/bin/python3 - <<'PY'
            import json
            import os
            from pathlib import Path

            target = Path("/run/matrix-synapse/runtime-config.yaml")
            target.unlink(missing_ok=True)
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
  }
]
