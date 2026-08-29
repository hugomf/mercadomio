package userbrew

import "net/url"

type OrganizationItem struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	Description *string `json:"description,omitempty"`
	CreatedAt   string  `json:"created_at"`
	UpdatedAt   string  `json:"updated_at"`
}

type CreateOrganizationRequest struct {
	Name        string  `json:"name"`
	Description *string `json:"description,omitempty"`
}

type UpdateOrganizationRequest struct {
	Name        *string `json:"name,omitempty"`
	Description *string `json:"description,omitempty"`
}

type OrgsAPI struct{ client *Client }

func (a *OrgsAPI) List() ([]OrganizationItem, error) {
	var out []OrganizationItem
	return out, a.client.get("/admin/organizations", &out)
}

func (a *OrgsAPI) Create(req CreateOrganizationRequest) (*OrganizationItem, error) {
	var out OrganizationItem
	return &out, a.client.post("/admin/organizations", req, &out)
}

func (a *OrgsAPI) Update(id string, req UpdateOrganizationRequest) (*OrganizationItem, error) {
	var out OrganizationItem
	return &out, a.client.put("/admin/organizations/"+url.PathEscape(id), req, &out)
}

func (a *OrgsAPI) Delete(id string) error {
	return a.client.delete("/admin/organizations/" + url.PathEscape(id))
}
