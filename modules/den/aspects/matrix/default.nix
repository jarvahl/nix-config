{ den, ... }:
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
        includes = with den.aspects.sops; [
          (secret { name = passwordSecret; } { hjem = { }; })
          (secret { name = "${name}/matrix/user_id"; } { hjem = { }; })
          (template
            {
              content = secrets: ''
                MATRIX_PASSWORD="${secrets."${passwordSecret}"}"
                MATRIX_USER_ID="${secrets."${name}/matrix/user_id"}"
              '';
              mode = "0400";
              name = "${name}-matrix-environment";
            }
            {
              hjem = { path, ... }: {
                systemd.services.${name}.serviceConfig.EnvironmentFile = path;
              };
            }
          )
        ];
        nixos.services.matrix.users.${name} = {
          inherit avatar displayName passwordSecret;
        };
      };
    includes = with den.aspects.sops; [
      (secret { name = "matrix/admin_password"; } { nixos = { }; })
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
  };

  perSystem.terranix.terranixConfigurations.terranix.modules = [
    (
      { ... }:
      {

      }
    )
  ];
}
