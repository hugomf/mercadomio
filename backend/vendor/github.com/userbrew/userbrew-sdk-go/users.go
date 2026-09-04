package userbrew

import (
	"fmt"
	"net/url"
)

type UserItem struct {
	UserID      string  `json:"user_id"`
	Email       string  `json:"email"`
	Username    string  `json:"username"`
	DisplayName *string `json:"display_name,omitempty"`
	Status      string  `json:"status"`
	Permissions string  `json:"permissions"`
	CreatedAt   string  `json:"created_at"`
	LastLoginAt *string `json:"last_login_at,omitempty"`
}

type CreateUserRequest struct {
	Email       string  `json:"email"`
	Username    string  `json:"username,omitempty"`
	Password    string  `json:"password"`
	DisplayName *string `json:"display_name,omitempty"`
}

type CreateUserResponse struct {
	UserID       string `json:"user_id"`
	AdminCreated bool   `json:"admin_created"`
}

type UpdateUserRequest struct {
	Email       *string `json:"email,omitempty"`
	Username    *string `json:"username,omitempty"`
	DisplayName *string `json:"display_name,omitempty"`
	Status      *string `json:"status,omitempty"`
}

type UpdateUserResponse struct {
	UserID      string  `json:"user_id"`
	Email       string  `json:"email"`
	Username    string  `json:"username"`
	DisplayName *string `json:"display_name,omitempty"`
	Status      string  `json:"status"`
}

type LockUserResponse struct {
	Locked bool `json:"locked"`
}

type UsersListParams struct {
	Page        *int64  `json:"page,omitempty"`
	PerPage     *int64  `json:"per_page,omitempty"`
	Email       *string `json:"email,omitempty"`
	Username    *string `json:"username,omitempty"`
	DisplayName *string `json:"display_name,omitempty"`
	Status      *string `json:"status,omitempty"`
}

type UsersAPI struct{ client *Client }

func (a *UsersAPI) List(params *UsersListParams) (*PaginatedUsers[UserItem], error) {
	q := url.Values{}
	if params != nil {
		if params.Page != nil { q.Set("page", fmt.Sprintf("%d", *params.Page)) }
		if params.PerPage != nil { q.Set("per_page", fmt.Sprintf("%d", *params.PerPage)) }
		if params.Email != nil { q.Set("email", *params.Email) }
		if params.Username != nil { q.Set("username", *params.Username) }
		if params.DisplayName != nil { q.Set("display_name", *params.DisplayName) }
		if params.Status != nil { q.Set("status", *params.Status) }
	}
	path := "/admin/users"
	if s := q.Encode(); s != "" { path += "?" + s }
	var out PaginatedUsers[UserItem]
	return &out, a.client.get(path, &out)
}

func (a *UsersAPI) Get(identifier string) (any, error) {
	var out any
	return out, a.client.get("/admin/users/"+url.PathEscape(identifier), &out)
}

func (a *UsersAPI) Create(req CreateUserRequest) (*CreateUserResponse, error) {
	var out CreateUserResponse
	return &out, a.client.post("/admin/users", req, &out)
}

func (a *UsersAPI) Update(identifier string, req UpdateUserRequest) (*UpdateUserResponse, error) {
	var out UpdateUserResponse
	return &out, a.client.put("/admin/users/"+url.PathEscape(identifier), req, &out)
}

func (a *UsersAPI) Delete(identifier string) error {
	return a.client.delete("/admin/users/" + url.PathEscape(identifier))
}

func (a *UsersAPI) Lock(identifier string) (*LockUserResponse, error) {
	var out LockUserResponse
	return &out, a.client.post("/admin/users/"+url.PathEscape(identifier)+"/lock", nil, &out)
}

func (a *UsersAPI) Unlock(identifier string) (*LockUserResponse, error) {
	var out LockUserResponse
	return &out, a.client.post("/admin/users/"+url.PathEscape(identifier)+"/unlock", nil, &out)
}

func (a *UsersAPI) AssignRole(identifier, role string) (any, error) {
	var out any
	return out, a.client.post("/admin/users/"+url.PathEscape(identifier)+"/roles", map[string]string{"role": role}, &out)
}
