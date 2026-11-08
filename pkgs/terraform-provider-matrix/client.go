package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
)

type matrixClient struct {
	accessToken   string
	adminPassword string
	adminUserID   string
	base          string
	http          *http.Client
	tokenMu       sync.Mutex
}

func newMatrixClient(base, accessToken, adminUserID, adminPassword string) (*matrixClient, error) {
	if base == "" {
		return nil, fmt.Errorf("homeserver_url or MATRIX_HOMESERVER_URL is required")
	}
	return &matrixClient{
		accessToken:   accessToken,
		adminPassword: adminPassword,
		adminUserID:   adminUserID,
		base:          strings.TrimRight(base, "/"),
		http:          &http.Client{Timeout: 30 * time.Second},
	}, nil
}

func (c *matrixClient) request(ctx context.Context, method, path, token string, body any, contentType string) (map[string]any, error) {
	var reader io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reader = bytes.NewReader(data)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.base+path, reader)
	if err != nil {
		return nil, err
	}
	if body != nil {
		req.Header.Set("Content-Type", contentType)
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	for attempt := 0; attempt < 4; attempt++ {
		if attempt > 0 && req.GetBody != nil {
			body, err := req.GetBody()
			if err != nil {
				return nil, err
			}
			req.Body = body
		}
		resp, err := c.http.Do(req)
		if err != nil {
			return nil, err
		}
		data, _ := io.ReadAll(resp.Body)
		resp.Body.Close()
		if resp.StatusCode == http.StatusTooManyRequests && attempt < 3 {
			var limited struct {
				RetryAfterMS int `json:"retry_after_ms"`
			}
			if json.Unmarshal(data, &limited) == nil && limited.RetryAfterMS > 0 {
				timer := time.NewTimer(time.Duration(limited.RetryAfterMS) * time.Millisecond)
				select {
				case <-ctx.Done():
					timer.Stop()
					return nil, ctx.Err()
				case <-timer.C:
				}
				continue
			}
		}
		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			return nil, fmt.Errorf("Matrix API returned HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(data)))
		}
		if len(data) == 0 {
			return map[string]any{}, nil
		}
		var result map[string]any
		if err := json.Unmarshal(data, &result); err != nil {
			return nil, err
		}
		return result, nil
	}
	return nil, fmt.Errorf("Matrix API request rate limit retries exhausted")
}

func (c *matrixClient) setUserPassword(ctx context.Context, userID, password string) error {
	token, err := c.adminToken(ctx)
	if err != nil {
		return fmt.Errorf("admin authentication: %w", err)
	}
	_, err = c.request(ctx, http.MethodPut, "/_synapse/admin/v2/users/"+url.PathEscape(userID), token, map[string]any{
		"password": password,
	}, "application/json")
	return err
}

func (c *matrixClient) adminToken(ctx context.Context) (string, error) {
	if c.accessToken != "" {
		return c.accessToken, nil
	}
	c.tokenMu.Lock()
	defer c.tokenMu.Unlock()
	if c.accessToken != "" {
		return c.accessToken, nil
	}
	if c.adminUserID == "" || c.adminPassword == "" {
		return "", fmt.Errorf("configure MATRIX_ACCESS_TOKEN or MATRIX_ADMIN_USER_ID and MATRIX_ADMIN_PASSWORD")
	}
	token, _, err := c.login(ctx, c.adminUserID, c.adminPassword)
	if err != nil {
		return "", err
	}
	c.accessToken = token
	return token, nil
}

func (c *matrixClient) userID(username string) string {
	if colon := strings.IndexByte(c.adminUserID, ':'); colon >= 0 {
		return "@" + username + c.adminUserID[colon:]
	}
	server := c.base
	if parsed, err := url.Parse(c.base); err == nil && parsed.Host != "" {
		server = parsed.Host
	}
	return "@" + username + ":" + server
}

func (c *matrixClient) createUser(ctx context.Context, userID, password string) error {
	token, err := c.adminToken(ctx)
	if err != nil {
		return err
	}
	_, err = c.request(ctx, http.MethodPut, "/_synapse/admin/v2/users/"+url.PathEscape(userID), token, map[string]any{
		"admin":       false,
		"displayname": userID,
		"password":    password,
	}, "application/json")
	return err
}

func (c *matrixClient) login(ctx context.Context, username, password string) (string, string, error) {
	identifier := map[string]any{
		"type": "m.id.user",
		"user": username,
	}
	result, err := c.request(ctx, http.MethodPost, "/_matrix/client/v3/login", "", map[string]any{
		"type":       "m.login.password",
		"identifier": identifier,
		"password":   password,
	}, "application/json")
	if err != nil {
		return "", "", err
	}
	token, _ := result["access_token"].(string)
	userID, _ := result["user_id"].(string)
	if token == "" || userID == "" {
		return "", "", fmt.Errorf("Matrix login response did not contain access_token and user_id")
	}
	return token, userID, nil
}

func profilePath(userID, field string) string {
	return "/_matrix/client/v3/profile/" + url.PathEscape(userID) + "/" + field
}
