package userbrew

import "net/url"

type GroupItem struct {
	ID             string  `json:"id"`
	OrganizationID *string `json:"organization_id,omitempty"`
	Name           string  `json:"name"`
	Description    *string `json:"description,omitempty"`
	CreatedAt      string  `json:"created_at"`
	UpdatedAt      string  `json:"updated_at"`
}

type CreateGroupRequest struct {
	Name        string  `json:"name"`
	Description *string `json:"description,omitempty"`
}

type UpdateGroupRequest struct {
	Name        *string `json:"name,omitempty"`
	Description *string `json:"description,omitempty"`
}

type GroupMemberItem struct {
	UserID      string  `json:"user_id"`
	DisplayName *string `json:"display_name,omitempty"`
	Email       *string `json:"email,omitempty"`
	AddedAt     string  `json:"added_at"`
}

type AddGroupMemberRequest struct {
	UserID string `json:"user_id"`
}

type GroupsAPI struct{ client *Client }

func (a *GroupsAPI) List() ([]GroupItem, error) {
	var out []GroupItem
	return out, a.client.get("/admin/groups", &out)
}

func (a *GroupsAPI) Create(req CreateGroupRequest) (*GroupItem, error) {
	var out GroupItem
	return &out, a.client.post("/admin/groups", req, &out)
}

func (a *GroupsAPI) Update(id string, req UpdateGroupRequest) (any, error) {
	var out any
	return out, a.client.put("/admin/groups/"+url.PathEscape(id), req, &out)
}

func (a *GroupsAPI) Delete(id string) error {
	return a.client.delete("/admin/groups/" + url.PathEscape(id))
}

func (a *GroupsAPI) Members(id string) ([]GroupMemberItem, error) {
	var out []GroupMemberItem
	return out, a.client.get("/admin/groups/"+url.PathEscape(id)+"/members", &out)
}

func (a *GroupsAPI) AddMember(id string, req AddGroupMemberRequest) (any, error) {
	var out any
	return out, a.client.post("/admin/groups/"+url.PathEscape(id)+"/members", req, &out)
}

func (a *GroupsAPI) RemoveMember(id, userID string) error {
	return a.client.delete("/admin/groups/" + url.PathEscape(id) + "/members/" + url.PathEscape(userID))
}
