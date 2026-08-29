package userbrew

import "net/url"

type LdapConfigItem struct {
	OrganizationID      string `json:"organization_id"`
	Enabled             bool   `json:"enabled"`
	Url                 string `json:"url"`
	BaseDN              string `json:"base_dn"`
	UserFilter          string `json:"user_filter"`
	BindDN              *string `json:"bind_dn,omitempty"`
	TimeoutSeconds      int64  `json:"timeout_seconds"`
	Attributes          any    `json:"attributes"`
	AutoCreateUsers     bool   `json:"auto_create_users"`
	FollowReferrals     bool   `json:"follow_referrals"`
	ActiveDirectoryMode bool   `json:"active_directory_mode"`
	Tls                 any    `json:"tls"`
	Pool                any    `json:"pool"`
	GroupRoleMappings   any    `json:"group_role_mappings"`
	CreatedAt           string `json:"created_at"`
	UpdatedAt           string `json:"updated_at"`
	CreatedBy           *string `json:"created_by,omitempty"`
}

type CreateLDAPConfigRequest struct {
	OrganizationID      string `json:"organization_id"`
	Url                 *string `json:"url,omitempty"`
	BaseDN              *string `json:"base_dn,omitempty"`
	UserFilter          *string `json:"user_filter,omitempty"`
	BindDN              *string `json:"bind_dn,omitempty"`
	BindPassword        *string `json:"bind_password,omitempty"`
	TimeoutSeconds      *int64  `json:"timeout_seconds,omitempty"`
	Attributes          any     `json:"attributes,omitempty"`
	AutoCreateUsers     *bool   `json:"auto_create_users,omitempty"`
	FollowReferrals     *bool   `json:"follow_referrals,omitempty"`
	ActiveDirectoryMode *bool   `json:"active_directory_mode,omitempty"`
	Tls                 any     `json:"tls,omitempty"`
	Pool                any     `json:"pool,omitempty"`
	GroupRoleMappings   any     `json:"group_role_mappings,omitempty"`
}

type UpdateLDAPConfigRequest struct {
	Url                 *string `json:"url,omitempty"`
	BaseDN              *string `json:"base_dn,omitempty"`
	UserFilter          *string `json:"user_filter,omitempty"`
	BindDN              *string `json:"bind_dn,omitempty"`
	BindPassword        *string `json:"bind_password,omitempty"`
	TimeoutSeconds      *int64  `json:"timeout_seconds,omitempty"`
	Attributes          any     `json:"attributes,omitempty"`
	AutoCreateUsers     *bool   `json:"auto_create_users,omitempty"`
	FollowReferrals     *bool   `json:"follow_referrals,omitempty"`
	ActiveDirectoryMode *bool   `json:"active_directory_mode,omitempty"`
	Tls                 any     `json:"tls,omitempty"`
	Pool                any     `json:"pool,omitempty"`
	GroupRoleMappings   any     `json:"group_role_mappings,omitempty"`
}

type LDAPAPI struct{ client *Client }

func (a *LDAPAPI) List() ([]LdapConfigItem, error) {
	var out []LdapConfigItem
	return out, a.client.get("/admin/ldap-configs", &out)
}

func (a *LDAPAPI) Get(orgId string) (*LdapConfigItem, error) {
	var out LdapConfigItem
	return &out, a.client.get("/admin/organizations/"+url.PathEscape(orgId)+"/ldap-config", &out)
}

func (a *LDAPAPI) Create(orgId string, req CreateLDAPConfigRequest) (any, error) {
	var out any
	return out, a.client.post("/admin/organizations/"+url.PathEscape(orgId)+"/ldap-config", req, &out)
}

func (a *LDAPAPI) Update(orgId string, req UpdateLDAPConfigRequest) (any, error) {
	var out any
	return out, a.client.put("/admin/organizations/"+url.PathEscape(orgId)+"/ldap-config", req, &out)
}

func (a *LDAPAPI) Delete(orgId string) error {
	return a.client.delete("/admin/organizations/" + url.PathEscape(orgId) + "/ldap-config")
}

func (a *LDAPAPI) Enable(orgId string) error {
	return a.client.post("/admin/organizations/"+url.PathEscape(orgId)+"/ldap-config/enable", nil, nil)
}

func (a *LDAPAPI) Disable(orgId string) error {
	return a.client.post("/admin/organizations/"+url.PathEscape(orgId)+"/ldap-config/disable", nil, nil)
}
