package main

import (
	"context"
	"fmt"
	"net/http"
	"net/url"

	"github.com/hashicorp/terraform-plugin-sdk/v2/diag"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func matrixUserAdminResource() *schema.Resource {
	return &schema.Resource{
		CreateContext: matrixUserAdminCreate,
		DeleteContext: matrixUserAdminDelete,
		Importer:      &schema.ResourceImporter{StateContext: matrixUserAdminImport},
		ReadContext:   matrixUserAdminRead,
		UpdateContext: matrixUserAdminUpdate,
		Schema: map[string]*schema.Schema{
			"user_id": {
				Type:     schema.TypeString,
				Required: true,
			},
		},
	}
}

func matrixUserAdminCreate(ctx context.Context, data *schema.ResourceData, meta any) diag.Diagnostics {
	client := meta.(*matrixClient)
	userID := data.Get("user_id").(string)
	if err := client.setAdmin(ctx, userID, true); err != nil {
		return diag.Errorf("grant Matrix administrator status to %q: %v", userID, err)
	}
	data.SetId(userID)
	return nil
}

func matrixUserAdminUpdate(ctx context.Context, data *schema.ResourceData, meta any) diag.Diagnostics {
	return matrixUserAdminCreate(ctx, data, meta)
}

func matrixUserAdminRead(ctx context.Context, data *schema.ResourceData, meta any) diag.Diagnostics {
	client := meta.(*matrixClient)
	userID := data.Get("user_id").(string)
	admin, err := client.isAdmin(ctx, userID)
	if err != nil {
		return diag.Errorf("read Matrix administrator status for %q: %v", userID, err)
	}
	if !admin {
		data.SetId("")
	}
	return nil
}

func matrixUserAdminDelete(ctx context.Context, data *schema.ResourceData, meta any) diag.Diagnostics {
	client := meta.(*matrixClient)
	if err := client.setAdmin(ctx, data.Get("user_id").(string), false); err != nil {
		return diag.Errorf("revoke Matrix administrator status from %q: %v", data.Get("user_id"), err)
	}
	data.SetId("")
	return nil
}

func matrixUserAdminImport(_ context.Context, data *schema.ResourceData, _ interface{}) ([]*schema.ResourceData, error) {
	if data.Id() == "" {
		return nil, fmt.Errorf("import ID must be a Matrix user ID")
	}
	if _, err := url.Parse(data.Id()); err != nil {
		return nil, err
	}
	data.Set("user_id", data.Id())
	return []*schema.ResourceData{data}, nil
}

func (c *matrixClient) setAdmin(ctx context.Context, userID string, admin bool) error {
	token, err := c.adminToken(ctx)
	if err != nil {
		return fmt.Errorf("admin authentication: %w", err)
	}
	_, err = c.request(ctx, http.MethodPut, "/_synapse/admin/v2/users/"+url.PathEscape(userID), token, map[string]bool{
		"admin": admin,
	}, "application/json")
	return err
}

func (c *matrixClient) isAdmin(ctx context.Context, userID string) (bool, error) {
	token, err := c.adminToken(ctx)
	if err != nil {
		return false, fmt.Errorf("admin authentication: %w", err)
	}
	result, err := c.request(ctx, http.MethodGet, "/_synapse/admin/v2/users/"+url.PathEscape(userID), token, nil, "")
	if err != nil {
		return false, err
	}
	admin, ok := result["admin"].(bool)
	if !ok {
		return false, fmt.Errorf("Synapse user response did not contain admin")
	}
	return admin, nil
}
