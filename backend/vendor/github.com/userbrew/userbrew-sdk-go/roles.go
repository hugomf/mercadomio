package userbrew

import "net/url"

type RoleItem struct {
	RoleID      string   `json:"role_id"`
	Name        string   `json:"name"`
	Permissions []string `json:"permissions"`
	Inherits    []string `json:"inherits"`
}

type CreateRoleRequest struct {
	Name        string   `json:"name"`
	Permissions []string `json:"permissions,omitempty"`
	Inherits    []string `json:"inherits,omitempty"`
}

type CreateRoleResponse struct {
	RoleID      string   `json:"role_id"`
	Name        string   `json:"name"`
	Permissions []string `json:"permissions"`
	Inherits    []string `json:"inherits"`
}

type UpdateRoleRequest struct {
	Name        *string  `json:"name,omitempty"`
	Permissions []string `json:"permissions,omitempty"`
}

type RolesListResponse struct {
	Roles []RoleItem `json:"roles"`
}

type RolesAPI struct{ client *Client }

func (a *RolesAPI) List() ([]RoleItem, error) {
	var out []RoleItem
	return out, a.client.get("/admin/roles", &out)
}

func (a *RolesAPI) Create(req CreateRoleRequest) (*CreateRoleResponse, error) {
	var out CreateRoleResponse
	return &out, a.client.post("/admin/roles", req, &out)
}

func (a *RolesAPI) Update(id string, req UpdateRoleRequest) (any, error) {
	var out any
	return out, a.client.put("/admin/roles/"+url.PathEscape(id), req, &out)
}

func (a *RolesAPI) Delete(id string) error {
	return a.client.delete("/admin/roles/" + url.PathEscape(id))
}
