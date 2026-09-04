package userbrew

import "net/url"

type AdminAPIKeyItem struct {
	ID         string  `json:"id"`
	UserID     string  `json:"user_id"`
	UserEmail  *string `json:"user_email,omitempty"`
	UserName   *string `json:"user_name,omitempty"`
	Name       string  `json:"name"`
	Prefix     string  `json:"prefix"`
	Status     string  `json:"status"`
	Scopes     *string `json:"scopes,omitempty"`
	CreatedAt  string  `json:"created_at"`
	LastUsedAt *string `json:"last_used_at,omitempty"`
	ExpiresAt  *string `json:"expires_at,omitempty"`
}

type CreateAdminAPIKeyRequest struct {
	UserID string   `json:"user_id"`
	Name   *string  `json:"name,omitempty"`
	Scopes []string `json:"scopes,omitempty"`
}

type CreateAdminAPIKeyResponse struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Key    string `json:"key"`
	Prefix string `json:"prefix"`
}

type UpdateAdminAPIKeyRequest struct {
	Name   *string  `json:"name,omitempty"`
	Status *string  `json:"status,omitempty"`
	Scopes []string `json:"scopes,omitempty"`
}

type APIKeysAPI struct{ client *Client }

func (a *APIKeysAPI) List() ([]AdminAPIKeyItem, error) {
	var out []AdminAPIKeyItem
	return out, a.client.get("/admin/api-keys", &out)
}

func (a *APIKeysAPI) Create(req CreateAdminAPIKeyRequest) (*CreateAdminAPIKeyResponse, error) {
	var out CreateAdminAPIKeyResponse
	return &out, a.client.post("/admin/api-keys", req, &out)
}

func (a *APIKeysAPI) Update(id string, req UpdateAdminAPIKeyRequest) (any, error) {
	var out any
	return out, a.client.put("/admin/api-keys/"+url.PathEscape(id), req, &out)
}

func (a *APIKeysAPI) Delete(id string) error {
	return a.client.delete("/admin/api-keys/" + url.PathEscape(id))
}
