package main

import (
	"context"
	"os"

	"github.com/hashicorp/terraform-plugin-sdk/v2/diag"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
	"github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{ProviderFunc: func() *schema.Provider {
		return Provider()
	}})
}

func Provider() *schema.Provider {
	p := &schema.Provider{
		Schema: map[string]*schema.Schema{
			"homeserver_url": {
				Type:        schema.TypeString,
				Optional:    true,
				DefaultFunc: schema.EnvDefaultFunc("MATRIX_HOMESERVER_URL", nil),
			},
			"admin_password": {
				Type:        schema.TypeString,
				Optional:    true,
				Sensitive:   true,
				DefaultFunc: schema.EnvDefaultFunc("MATRIX_ADMIN_PASSWORD", nil),
			},
			"admin_user_id": {
				Type:        schema.TypeString,
				Optional:    true,
				DefaultFunc: schema.EnvDefaultFunc("MATRIX_ADMIN_USER_ID", nil),
			},
			"access_token": {
				Type:        schema.TypeString,
				Optional:    true,
				Sensitive:   true,
				DefaultFunc: schema.EnvDefaultFunc("MATRIX_ACCESS_TOKEN", nil),
			},
		},
		ResourcesMap: map[string]*schema.Resource{
			"matrix_user":       matrixUserResource(),
			"matrix_user_admin": matrixUserAdminResource(),
		},
	}
	p.ConfigureContextFunc = func(_ context.Context, data *schema.ResourceData) (any, diag.Diagnostics) {
		homeserver := data.Get("homeserver_url").(string)
		if homeserver == "" {
			homeserver = os.Getenv("MATRIX_HOMESERVER_URL")
		}
		client, err := newMatrixClient(
			homeserver,
			data.Get("access_token").(string),
			data.Get("admin_user_id").(string),
			data.Get("admin_password").(string),
		)
		if err != nil {
			return nil, diag.Errorf("configure Matrix provider: %v", err)
		}
		return client, nil
	}
	return p
}
