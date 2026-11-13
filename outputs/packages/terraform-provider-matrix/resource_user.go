package main

import (
	"context"
	"crypto/rand"
	"fmt"
	"strings"

	"github.com/hashicorp/terraform-plugin-sdk/v2/diag"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func matrixUserResource() *schema.Resource {
	return &schema.Resource{
		CreateContext: matrixUserCreate,
		Importer:      &schema.ResourceImporter{StateContext: matrixUserImport},
		ReadContext:   matrixUserRead,
		UpdateContext: matrixUserUpdate,
		DeleteContext: matrixUserDelete,
		Schema: map[string]*schema.Schema{
			"username": {
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
			"password": {
				Type:      schema.TypeString,
				Computed:  true,
				Sensitive: true,
			},
			"display_name": {
				Type:     schema.TypeString,
				Required: true,
			},
			"avatar_file": {
				Type:     schema.TypeString,
				Optional: true,
			},
			"user_id": {
				Type:     schema.TypeString,
				Computed: true,
			},
			"avatar_url": {
				Type:     schema.TypeString,
				Computed: true,
			},
		},
	}
}

func matrixUserCreate(ctx context.Context, data *schema.ResourceData, meta any) diag.Diagnostics {
	client := meta.(*matrixClient)
	username := data.Get("username").(string)
	password, err := randomPassword()
	if err != nil {
		return diag.Errorf("generate password for Matrix user %q: %v", username, err)
	}
	data.Set("password", password)

	userID := client.userID(username)
	if err := client.createUser(ctx, userID, password); err != nil {
		return diag.Errorf("create Matrix user %q: %v", username, err)
	}
	data.SetId(userID)
	data.Set("user_id", userID)
	return updateMatrixUser(ctx, data, client)
}

func matrixUserRead(ctx context.Context, data *schema.ResourceData, meta any) diag.Diagnostics {
	client := meta.(*matrixClient)
	if data.Id() == "" {
		return nil
	}
	password := data.Get("password").(string)
	if password == "" {
		var generateErr error
		password, generateErr = randomPassword()
		if generateErr != nil {
			return diag.Errorf("generate password for Matrix user %q: %v", data.Get("username"), generateErr)
		}
		if err := client.setUserPassword(ctx, data.Id(), password); err != nil {
			return diag.Errorf("set password for imported Matrix user %q: %v", data.Get("username"), err)
		}
		data.Set("password", password)
	}
	_, userID, err := client.login(ctx, data.Get("username").(string), password)
	if err != nil {
		return diag.Errorf("read Matrix user %q: %v", data.Get("username"), err)
	}
	data.Set("user_id", userID)
	return nil
}

func matrixUserUpdate(ctx context.Context, data *schema.ResourceData, meta any) diag.Diagnostics {
	return updateMatrixUser(ctx, data, meta.(*matrixClient))
}

func updateMatrixUser(ctx context.Context, data *schema.ResourceData, client *matrixClient) diag.Diagnostics {
	password := data.Get("password").(string)
	token, userID, err := client.login(ctx, data.Get("username").(string), password)
	if err != nil {
		return diag.Errorf("login Matrix user %q: %v", data.Get("username"), err)
	}
	if err := client.setProfile(ctx, token, userID, data.Get("display_name").(string)); err != nil {
		return diag.Errorf("set Matrix display name for %q: %v", userID, err)
	}
	if filename := data.Get("avatar_file").(string); filename != "" {
		avatarURL, err := client.uploadAvatar(ctx, token, userID, filename)
		if err != nil {
			return diag.Errorf("set Matrix avatar for %q: %v", userID, err)
		}
		data.Set("avatar_url", avatarURL)
	}
	data.Set("user_id", userID)
	return nil
}

func randomPassword() (string, error) {
	const alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
	data := make([]byte, 48)
	if _, err := rand.Read(data); err != nil {
		return "", err
	}
	for i := range data {
		data[i] = alphabet[int(data[i])%len(alphabet)]
	}
	return string(data), nil
}

func matrixUserImport(_ context.Context, data *schema.ResourceData, _ interface{}) ([]*schema.ResourceData, error) {
	id := data.Id()
	username := id
	if len(id) > 1 && id[0] == '@' {
		username = strings.TrimPrefix(id, "@")
		if at := strings.IndexByte(username, ':'); at >= 0 {
			username = username[:at]
		}
	}
	if username == "" {
		return nil, fmt.Errorf("import ID must be a Matrix user ID or username")
	}
	data.Set("username", username)
	return []*schema.ResourceData{data}, nil
}

func matrixUserDelete(_ context.Context, data *schema.ResourceData, _ any) diag.Diagnostics {
	// Deliberately do not deactivate or delete the Matrix account. Removing the
	// resource only stops Terraform management of the account.
	data.SetId("")
	return nil
}
