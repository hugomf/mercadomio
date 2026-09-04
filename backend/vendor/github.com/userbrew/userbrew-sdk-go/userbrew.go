package userbrew

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

type Client struct {
	baseURL string
	token   string
	http    *http.Client
}

func New(baseURL, token string) *Client {
	return &Client{
		baseURL: baseURL,
		token:   token,
		http:    &http.Client{},
	}
}

func NewFromEnv() *Client {
	url := os.Getenv("USERBREW_URL")
	if url == "" {
		url = "http://localhost:3000"
	}
	return New(url, os.Getenv("USERBREW_ADMIN_TOKEN"))
}

func (c *Client) SetToken(token string) { c.token = token }
func (c *Client) BaseURL() string       { return c.baseURL }

func (c *Client) do(method, path string, body, dst any) error {
	var buf bytes.Buffer
	if body != nil {
		if err := json.NewEncoder(&buf).Encode(body); err != nil {
			return fmt.Errorf("encode body: %w", err)
		}
	}
	req, err := http.NewRequest(method, c.baseURL+path, &buf)
	if err != nil {
		return fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return fmt.Errorf("http request: %w", err)
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	if resp.StatusCode == http.StatusNoContent {
		return nil
	}
	if resp.StatusCode >= 300 {
		var e struct {
			Message string `json:"message"`
			Error   string `json:"error"`
		}
		json.Unmarshal(raw, &e)
		msg := e.Message
		if msg == "" {
			msg = e.Error
		}
		if msg == "" {
			msg = resp.Status
		}
		return &APIError{Status: resp.StatusCode, Message: msg}
	}
	if dst != nil {
		if err := json.Unmarshal(raw, dst); err != nil {
			return fmt.Errorf("decode response: %w", err)
		}
	}
	return nil
}

func (c *Client) get(path string, dst any) error  { return c.do(http.MethodGet, path, nil, dst) }
func (c *Client) post(path string, body, dst any) error  { return c.do(http.MethodPost, path, body, dst) }
func (c *Client) put(path string, body, dst any) error   { return c.do(http.MethodPut, path, body, dst) }
func (c *Client) patch(path string, body, dst any) error { return c.do(http.MethodPatch, path, body, dst) }
func (c *Client) delete(path string) error               { return c.do(http.MethodDelete, path, nil, nil) }
func (c *Client) deleteInto(path string, dst any) error  { return c.do(http.MethodDelete, path, nil, dst) }

// Accessors

func (c *Client) Users() *UsersAPI              { return &UsersAPI{client: c} }
func (c *Client) Roles() *RolesAPI              { return &RolesAPI{client: c} }
func (c *Client) Orgs() *OrgsAPI                { return &OrgsAPI{client: c} }
func (c *Client) Groups() *GroupsAPI            { return &GroupsAPI{client: c} }
func (c *Client) Apps() *AppsAPI                { return &AppsAPI{client: c} }
func (c *Client) APIKeys() *APIKeysAPI          { return &APIKeysAPI{client: c} }
func (c *Client) Audit() *AuditAPI              { return &AuditAPI{client: c} }
func (c *Client) Stats() *StatsAPI              { return &StatsAPI{client: c} }
func (c *Client) Sentinels() *SentinelsAPI      { return &SentinelsAPI{client: c} }
func (c *Client) OAuthClients() *OAuthClientsAPI { return &OAuthClientsAPI{client: c} }
func (c *Client) Flows() *FlowsAPI              { return &FlowsAPI{client: c} }
func (c *Client) Stages() *StagesAPI            { return &StagesAPI{client: c} }
func (c *Client) Policies() *PoliciesAPI        { return &PoliciesAPI{client: c} }
func (c *Client) SAML() *SAMLAPI                { return &SAMLAPI{client: c} }
func (c *Client) Kerberos() *KerberosAPI        { return &KerberosAPI{client: c} }
func (c *Client) LDAP() *LDAPAPI                { return &LDAPAPI{client: c} }
