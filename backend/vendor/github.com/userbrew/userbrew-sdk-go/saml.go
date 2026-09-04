package userbrew

import "net/url"

type SAMLConfigItem struct {
	OrganizationID    string  `json:"organization_id"`
	IDPEntityID       string  `json:"idp_entity_id"`
	IDPSSOURL         string  `json:"idp_sso_url"`
	IDPSLOURL         *string `json:"idp_slo_url,omitempty"`
	NameIDFormat      string  `json:"name_id_format"`
	SPEntityID        string  `json:"sp_entity_id"`
	SPACSURL          string  `json:"sp_acs_url"`
	SPSLOURL          *string `json:"sp_slo_url,omitempty"`
	Enabled           bool    `json:"enabled"`
	SignAuthnRequests bool    `json:"sign_authn_requests"`
	SignAssertions    bool    `json:"sign_assertions"`
	SignResponses     bool    `json:"sign_responses"`
	EncryptAssertions bool    `json:"encrypt_assertions"`
}

type CreateSAMLConfigRequest struct {
	OrganizationID       string         `json:"organization_id"`
	IDPEntityID          string         `json:"idp_entity_id"`
	IDPSSOURL            string         `json:"idp_sso_url"`
	IDPSLOURL            *string        `json:"idp_slo_url,omitempty"`
	IDPPublicCertificate string         `json:"idp_public_certificate"`
	NameIDFormat         *string        `json:"name_id_format,omitempty"`
	SPEntityID           *string        `json:"sp_entity_id,omitempty"`
	SPACSURL             *string        `json:"sp_acs_url,omitempty"`
	SPSLOURL             *string        `json:"sp_slo_url,omitempty"`
	SPPrivateKey         *string        `json:"sp_private_key,omitempty"`
	SPPublicCertificate  *string        `json:"sp_public_certificate,omitempty"`
	AttributeMapping     map[string]any `json:"attribute_mapping,omitempty"`
	Enabled              *bool          `json:"enabled,omitempty"`
	SignAuthnRequests    *bool          `json:"sign_authn_requests,omitempty"`
	SignAssertions       *bool          `json:"sign_assertions,omitempty"`
	SignResponses        *bool          `json:"sign_responses,omitempty"`
	EncryptAssertions    *bool          `json:"encrypt_assertions,omitempty"`
}

type UpdateSAMLConfigRequest struct {
	IDPEntityID          *string        `json:"idp_entity_id,omitempty"`
	IDPSSOURL            *string        `json:"idp_sso_url,omitempty"`
	IDPSLOURL            *string        `json:"idp_slo_url,omitempty"`
	IDPPublicCertificate *string        `json:"idp_public_certificate,omitempty"`
	NameIDFormat         *string        `json:"name_id_format,omitempty"`
	SPEntityID           *string        `json:"sp_entity_id,omitempty"`
	SPACSURL             *string        `json:"sp_acs_url,omitempty"`
	SPSLOURL             *string        `json:"sp_slo_url,omitempty"`
	SPPrivateKey         *string        `json:"sp_private_key,omitempty"`
	SPPublicCertificate  *string        `json:"sp_public_certificate,omitempty"`
	AttributeMapping     map[string]any `json:"attribute_mapping,omitempty"`
	Enabled              *bool          `json:"enabled,omitempty"`
	SignAuthnRequests    *bool          `json:"sign_authn_requests,omitempty"`
	SignAssertions       *bool          `json:"sign_assertions,omitempty"`
	SignResponses        *bool          `json:"sign_responses,omitempty"`
	EncryptAssertions    *bool          `json:"encrypt_assertions,omitempty"`
}

type SAMLAPI struct{ client *Client }

func (a *SAMLAPI) List() ([]SAMLConfigItem, error) {
	var out []SAMLConfigItem
	return out, a.client.get("/admin/saml/config", &out)
}

func (a *SAMLAPI) Get(orgID string) (*SAMLConfigItem, error) {
	var out SAMLConfigItem
	return &out, a.client.get("/admin/saml/config/"+url.PathEscape(orgID), &out)
}

func (a *SAMLAPI) Create(req CreateSAMLConfigRequest) (*SAMLConfigItem, error) {
	var out SAMLConfigItem
	return &out, a.client.post("/admin/saml/config", req, &out)
}

func (a *SAMLAPI) Update(orgID string, req UpdateSAMLConfigRequest) (*SAMLConfigItem, error) {
	var out SAMLConfigItem
	return &out, a.client.put("/admin/saml/config/"+url.PathEscape(orgID), req, &out)
}

func (a *SAMLAPI) Delete(orgID string) (any, error) {
	var out any
	return out, a.client.deleteInto("/admin/saml/config/"+url.PathEscape(orgID), &out)
}
