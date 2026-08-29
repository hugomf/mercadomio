package userbrew

import "net/url"

type PolicyItem struct {
	ID         string         `json:"id"`
	Name       string         `json:"name"`
	PolicyType string         `json:"policy_type"`
	Config     map[string]any `json:"config"`
	CreatedAt  string         `json:"created_at"`
	UpdatedAt  string         `json:"updated_at"`
}

type CreatePolicyRequest struct {
	Name       string         `json:"name"`
	PolicyType string         `json:"policy_type"`
	Config     map[string]any `json:"config,omitempty"`
}

type UpdatePolicyRequest struct {
	Name       *string        `json:"name,omitempty"`
	PolicyType *string        `json:"policy_type,omitempty"`
	Config     map[string]any `json:"config,omitempty"`
}

type PoliciesAPI struct{ client *Client }

func (a *PoliciesAPI) List() ([]PolicyItem, error) {
	var out []PolicyItem
	return out, a.client.get("/admin/policies", &out)
}

func (a *PoliciesAPI) Get(id string) (*PolicyItem, error) {
	var out PolicyItem
	return &out, a.client.get("/admin/policies/"+url.PathEscape(id), &out)
}

func (a *PoliciesAPI) Create(req CreatePolicyRequest) (*PolicyItem, error) {
	var out PolicyItem
	return &out, a.client.post("/admin/policies", req, &out)
}

func (a *PoliciesAPI) Update(id string, req UpdatePolicyRequest) (*PolicyItem, error) {
	var out PolicyItem
	return &out, a.client.put("/admin/policies/"+url.PathEscape(id), req, &out)
}

func (a *PoliciesAPI) Delete(id string) error {
	return a.client.delete("/admin/policies/" + url.PathEscape(id))
}
