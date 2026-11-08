package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
)

func (c *matrixClient) setProfile(ctx context.Context, token, userID, displayName string) error {
	_, err := c.request(ctx, http.MethodPut, profilePath(userID, "displayname"), token, map[string]string{
		"displayname": displayName,
	}, "application/json")
	return err
}

func (c *matrixClient) uploadAvatar(ctx context.Context, token, userID, filename string) (string, error) {
	image, err := os.Open(filename)
	if err != nil {
		return "", err
	}
	defer image.Close()

	data, err := io.ReadAll(image)
	if err != nil {
		return "", err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.base+"/_matrix/media/v3/upload?filename="+url.QueryEscape(filepath.Base(filename)), bytes.NewReader(data))
	if err != nil {
		return "", err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/octet-stream")
	resp, err := c.http.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		data, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("Matrix media API returned HTTP %d: %s", resp.StatusCode, data)
	}
	var result struct {
		ContentURI string `json:"content_uri"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}
	if result.ContentURI == "" {
		return "", fmt.Errorf("Matrix media response did not contain content_uri")
	}
	_, err = c.request(ctx, http.MethodPut, profilePath(userID, "avatar_url"), token, map[string]string{
		"avatar_url": result.ContentURI,
	}, "application/json")
	return result.ContentURI, err
}
