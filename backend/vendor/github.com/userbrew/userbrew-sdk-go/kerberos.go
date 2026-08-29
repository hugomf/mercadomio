package userbrew

import "net/url"

type KerberosConfigItem struct {
	OrganizationID            string         `json:"organization_id"`
	Realm                     string         `json:"realm"`
	KDCHostname               string         `json:"kdc_hostname"`
	KDCPort                   int            `json:"kdc_port"`
	AdminServerHostname       *string        `json:"admin_server_hostname,omitempty"`
	AdminServerPort           *int           `json:"admin_server_port,omitempty"`
	ServicePrincipalName      string         `json:"service_principal_name"`
	AllowPlaintextPassword    bool           `json:"allow_plaintext_password"`
	RequirePreauthentication  bool           `json:"require_preauthentication"`
	TicketLifetimeSeconds     int64          `json:"ticket_lifetime_seconds"`
	ClockSkewToleranceSeconds int64          `json:"clock_skew_tolerance_seconds"`
	Enabled                   bool           `json:"enabled"`
	AutoProvisionUsers        bool           `json:"auto_provision_users"`
	AttributeMapping          map[string]any `json:"attribute_mapping,omitempty"`
}

type CreateKerberosConfigRequest struct {
	OrganizationID            string         `json:"organization_id"`
	Realm                     string         `json:"realm"`
	KDCHostname               string         `json:"kdc_hostname"`
	KDCPort                   int            `json:"kdc_port"`
	AdminServerHostname       *string        `json:"admin_server_hostname,omitempty"`
	AdminServerPort           *int           `json:"admin_server_port,omitempty"`
	ServicePrincipalName      string         `json:"service_principal_name"`
	AllowPlaintextPassword    bool           `json:"allow_plaintext_password"`
	RequirePreauthentication  bool           `json:"require_preauthentication"`
	TicketLifetimeSeconds     int64          `json:"ticket_lifetime_seconds"`
	ClockSkewToleranceSeconds int64          `json:"clock_skew_tolerance_seconds"`
	AutoProvisionUsers        *bool          `json:"auto_provision_users,omitempty"`
	AttributeMapping          map[string]any `json:"attribute_mapping,omitempty"`
}

type UpdateKerberosConfigRequest struct {
	Realm                     *string        `json:"realm,omitempty"`
	KDCHostname               *string        `json:"kdc_hostname,omitempty"`
	KDCPort                   *int           `json:"kdc_port,omitempty"`
	AdminServerHostname       *string        `json:"admin_server_hostname,omitempty"`
	AdminServerPort           *int           `json:"admin_server_port,omitempty"`
	ServicePrincipalName      *string        `json:"service_principal_name,omitempty"`
	AllowPlaintextPassword    *bool          `json:"allow_plaintext_password,omitempty"`
	RequirePreauthentication  *bool          `json:"require_preauthentication,omitempty"`
	TicketLifetimeSeconds     *int64         `json:"ticket_lifetime_seconds,omitempty"`
	ClockSkewToleranceSeconds *int64         `json:"clock_skew_tolerance_seconds,omitempty"`
	AutoProvisionUsers        *bool          `json:"auto_provision_users,omitempty"`
	AttributeMapping          map[string]any `json:"attribute_mapping,omitempty"`
}

type KerberosAPI struct{ client *Client }

func (a *KerberosAPI) List() ([]KerberosConfigItem, error) {
	var out []KerberosConfigItem
	return out, a.client.get("/admin/kerberos/config", &out)
}

func (a *KerberosAPI) Get(orgID string) (*KerberosConfigItem, error) {
	var out KerberosConfigItem
	return &out, a.client.get("/admin/kerberos/config/"+url.PathEscape(orgID), &out)
}

func (a *KerberosAPI) Create(req CreateKerberosConfigRequest) (*KerberosConfigItem, error) {
	var out KerberosConfigItem
	return &out, a.client.post("/admin/kerberos/config", req, &out)
}

func (a *KerberosAPI) Update(orgID string, req UpdateKerberosConfigRequest) (*KerberosConfigItem, error) {
	var out KerberosConfigItem
	return &out, a.client.put("/admin/kerberos/config/"+url.PathEscape(orgID), req, &out)
}

func (a *KerberosAPI) Delete(orgID string) error {
	return a.client.delete("/admin/kerberos/config/" + url.PathEscape(orgID))
}

func (a *KerberosAPI) Enable(orgID string) (*KerberosConfigItem, error) {
	var out KerberosConfigItem
	return &out, a.client.post("/admin/kerberos/config/"+url.PathEscape(orgID)+"/enable", nil, &out)
}

func (a *KerberosAPI) Disable(orgID string) (*KerberosConfigItem, error) {
	var out KerberosConfigItem
	return &out, a.client.post("/admin/kerberos/config/"+url.PathEscape(orgID)+"/disable", nil, &out)
}
