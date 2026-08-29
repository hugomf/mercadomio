package userbrew

import "net/url"

type ApplicationItem struct {
	ID           string  `json:"id"`
	Name         string  `json:"name"`
	Slug         string  `json:"slug"`
	Description  *string `json:"description,omitempty"`
	LaunchURL    *string `json:"launch_url,omitempty"`
	LoginURL     *string `json:"login_url,omitempty"`
	LogoURL      *string `json:"logo_url,omitempty"`
	Visibility   string  `json:"visibility"`
	ProviderType string  `json:"provider_type"`
	Enabled      bool    `json:"enabled"`
	CreatedAt    string  `json:"created_at"`
	UpdatedAt    string  `json:"updated_at"`
}

type CreateApplicationRequest struct {
	Name           string         `json:"name"`
	Description    *string        `json:"description,omitempty"`
	LaunchURL      *string        `json:"launch_url,omitempty"`
	LoginURL       *string        `json:"login_url,omitempty"`
	Visibility     string         `json:"visibility"`
	ProviderType   string         `json:"provider_type"`
	ProviderConfig map[string]any `json:"provider_config,omitempty"`
}

type UpdateApplicationRequest struct {
	Name           *string        `json:"name,omitempty"`
	Description    *string        `json:"description,omitempty"`
	LaunchURL      *string        `json:"launch_url,omitempty"`
	LoginURL       *string        `json:"login_url,omitempty"`
	LogoURL        *string        `json:"logo_url,omitempty"`
	Visibility     *string        `json:"visibility,omitempty"`
	ProviderType   *string        `json:"provider_type,omitempty"`
	Enabled        *bool          `json:"enabled,omitempty"`
	ProviderConfig *map[string]any `json:"provider_config,omitempty"`
}

type AssignmentItem struct {
	ID        string              `json:"id"`
	AppID     string              `json:"app_id"`
	UserID    string              `json:"user_id"`
	GrantedAt string              `json:"granted_at"`
	User      *AssignmentUserInfo `json:"user,omitempty"`
}

type AssignmentUserInfo struct {
	ID          string  `json:"id"`
	Email       string  `json:"email"`
	DisplayName *string `json:"display_name,omitempty"`
}

type AssignUserRequest struct {
	UserID string `json:"user_id"`
}

type ApplicationFlowBindingRequest struct {
	FlowID          *string `json:"flow_id,omitempty"`
	FlowEnforcement *string `json:"flow_enforcement,omitempty"`
}

type AppsAPI struct{ client *Client }

func (a *AppsAPI) List() ([]ApplicationItem, error) {
	var out []ApplicationItem
	return out, a.client.get("/admin/applications", &out)
}

func (a *AppsAPI) Get(id string) (any, error) {
	var out any
	return out, a.client.get("/admin/applications/"+url.PathEscape(id), &out)
}

func (a *AppsAPI) Create(req CreateApplicationRequest) (any, error) {
	var out any
	return out, a.client.post("/admin/applications", req, &out)
}

func (a *AppsAPI) Update(id string, req UpdateApplicationRequest) (any, error) {
	var out any
	return out, a.client.put("/admin/applications/"+url.PathEscape(id), req, &out)
}

func (a *AppsAPI) Delete(id string) error {
	return a.client.delete("/admin/applications/" + url.PathEscape(id))
}

func (a *AppsAPI) Assignments(id string) (any, error) {
	var out any
	return out, a.client.get("/admin/applications/"+url.PathEscape(id)+"/assignments", &out)
}

func (a *AppsAPI) AssignUser(id string, req AssignUserRequest) (any, error) {
	var out any
	return out, a.client.post("/admin/applications/"+url.PathEscape(id)+"/assign", req, &out)
}

func (a *AppsAPI) UnassignUser(id, userID string) (any, error) {
	var out any
	return out, a.client.delete("/admin/applications/" + url.PathEscape(id) + "/assign/" + url.PathEscape(userID))
}

func (a *AppsAPI) SetFlowBinding(id string, req ApplicationFlowBindingRequest) (any, error) {
	var out any
	return out, a.client.put("/admin/applications/"+url.PathEscape(id)+"/flow", req, &out)
}
