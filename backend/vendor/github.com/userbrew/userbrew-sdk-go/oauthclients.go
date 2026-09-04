package userbrew

import "net/url"

type OAuthClientItem struct {
	ClientID       string   `json:"client_id"`
	OrganizationID *string  `json:"organization_id,omitempty"`
	Name           string   `json:"name"`
	RedirectURIs   []string `json:"redirect_uris"`
	GrantTypes     []string `json:"grant_types"`
	ResponseTypes  []string `json:"response_types"`
	Scopes         []string `json:"scopes"`
	RequirePKCE    bool     `json:"require_pkce"`
	IsPublic       bool     `json:"is_public"`
	Enabled        bool     `json:"enabled"`
	AllowedOrigins []string `json:"allowed_origins"`
	CreatedAt      string   `json:"created_at"`
	UpdatedAt      string   `json:"updated_at"`
}

type CreateOAuthClientRequest struct {
	Name           string   `json:"name"`
	RedirectURIs   []string `json:"redirect_uris"`
	AllowedOrigins []string `json:"allowed_origins,omitempty"`
	GrantTypes     []string `json:"grant_types,omitempty"`
	ResponseTypes  []string `json:"response_types,omitempty"`
	Scopes         []string `json:"scopes,omitempty"`
	RequirePKCE    *bool    `json:"require_pkce,omitempty"`
	IsPublic       *bool    `json:"is_public,omitempty"`
	OrganizationID *string  `json:"organization_id,omitempty"`
}

type OAuthClientCreationResponse struct {
	Client       OAuthClientItem `json:"client"`
	ClientSecret *string         `json:"client_secret,omitempty"`
	Warning      *string         `json:"warning,omitempty"`
}

type UpdateOAuthClientRequest struct {
	Name           *string  `json:"name,omitempty"`
	RedirectURIs   []string `json:"redirect_uris,omitempty"`
	AllowedOrigins []string `json:"allowed_origins,omitempty"`
	GrantTypes     []string `json:"grant_types,omitempty"`
	ResponseTypes  []string `json:"response_types,omitempty"`
	Scopes         []string `json:"scopes,omitempty"`
	RequirePKCE    *bool    `json:"require_pkce,omitempty"`
	IsPublic       *bool    `json:"is_public,omitempty"`
	Enabled        *bool    `json:"enabled,omitempty"`
}

type RegenerateClientSecretResponse struct {
	ClientID     string `json:"clientId"`
	ClientSecret string `json:"clientSecret"`
}

type OAuthClientsAPI struct{ client *Client }

func (a *OAuthClientsAPI) List() ([]OAuthClientItem, error) {
	var out []OAuthClientItem
	return out, a.client.get("/admin/oauth-clients", &out)
}

func (a *OAuthClientsAPI) Get(id string) (*OAuthClientItem, error) {
	var out OAuthClientItem
	return &out, a.client.get("/admin/oauth-clients/"+url.PathEscape(id), &out)
}

func (a *OAuthClientsAPI) Create(req CreateOAuthClientRequest) (*OAuthClientCreationResponse, error) {
	var out OAuthClientCreationResponse
	return &out, a.client.post("/admin/oauth-clients", req, &out)
}

func (a *OAuthClientsAPI) Update(id string, req UpdateOAuthClientRequest) (*OAuthClientItem, error) {
	var out OAuthClientItem
	return &out, a.client.put("/admin/oauth-clients/"+url.PathEscape(id), req, &out)
}

func (a *OAuthClientsAPI) Delete(id string) error {
	return a.client.delete("/admin/oauth-clients/" + url.PathEscape(id))
}

func (a *OAuthClientsAPI) RegenerateSecret(id string) (*RegenerateClientSecretResponse, error) {
	var out RegenerateClientSecretResponse
	return &out, a.client.post("/admin/oauth-clients/"+url.PathEscape(id)+"/secret", nil, &out)
}
