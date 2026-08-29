package userbrew

import "net/url"

type SentinelItem struct {
	ID               string         `json:"id"`
	Name             string         `json:"name"`
	SentinelType     string         `json:"sentinelType"`
	Config           map[string]any `json:"config"`
	TokenPrefix      string         `json:"token_prefix"`
	HealthStatus     string         `json:"health_status"`
	LastSeenAt       *string        `json:"last_seen_at,omitempty"`
	CreatedAt        string         `json:"created_at"`
	UpdatedAt        string         `json:"updated_at"`
	ApplicationCount int            `json:"applicationCount"`
}

type CreateSentinelRequest struct {
	Name         string         `json:"name"`
	SentinelType *string        `json:"sentinelType,omitempty"`
	Config       map[string]any `json:"config,omitempty"`
}

type CreateSentinelResponse struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	SentinelType string `json:"sentinelType"`
	Token        string `json:"token"`
	TokenPrefix  string `json:"token_prefix"`
	HealthStatus string `json:"health_status"`
}

type UpdateSentinelRequest struct {
	Name   *string        `json:"name,omitempty"`
	Config map[string]any `json:"config,omitempty"`
}

type DeploySentinelResponse struct {
	ContainerID   string `json:"container_id"`
	ContainerName string `json:"container_name"`
	Status        string `json:"status"`
	Image         string `json:"image"`
	Port          int    `json:"port"`
}

type RestartSentinelResponse struct {
	ContainerID   string `json:"container_id"`
	ContainerName string `json:"container_name"`
	Status        string `json:"status"`
}

type SentinelHealthResponse struct {
	ContainerID string  `json:"container_id"`
	Status      string  `json:"status"`
	Message     *string `json:"message,omitempty"`
}

type SentinelApplicationItem struct {
	ID              string         `json:"id"`
	SentinelID      string         `json:"sentinel_id"`
	ApplicationID   string         `json:"application_id"`
	ApplicationName *string        `json:"application_name,omitempty"`
	MediationType   *string        `json:"mediationType,omitempty"`
	MediationConfig map[string]any `json:"mediationConfig,omitempty"`
	CreatedAt       string         `json:"created_at"`
}

type AttachSentinelAppRequest struct {
	ApplicationID   string         `json:"application_id"`
	MediationType   *string        `json:"mediationType,omitempty"`
	MediationConfig map[string]any `json:"mediationConfig,omitempty"`
}

type ResourceItem struct {
	ID            string         `json:"id"`
	ApplicationID string         `json:"application_id"`
	Path          string         `json:"path"`
	Methods       []string       `json:"methods"`
	Rules         []ResourceRule `json:"rules"`
	Priority      int64          `json:"priority"`
	CreatedAt     string         `json:"created_at"`
	UpdatedAt     string         `json:"updated_at"`
}

type ResourceRule struct {
	Effect     string          `json:"effect"`
	Conditions []RuleCondition `json:"conditions"`
}

type RuleCondition struct {
	Field    string `json:"field"`
	Operator string `json:"operator"`
	Value    string `json:"value"`
}

type CreateResourceRequest struct {
	ApplicationID string         `json:"application_id"`
	Path          string         `json:"path"`
	Methods       []string       `json:"methods"`
	Rules         []ResourceRule `json:"rules"`
	Priority      int64          `json:"priority"`
}

type UpdateResourceRequest struct {
	Path     *string        `json:"path,omitempty"`
	Methods  []string       `json:"methods,omitempty"`
	Rules    []ResourceRule `json:"rules,omitempty"`
	Priority *int64         `json:"priority,omitempty"`
}

type SentinelSessionItem struct {
	ID            string  `json:"id"`
	SentinelID    string  `json:"sentinel_id"`
	ApplicationID string  `json:"application_id"`
	UserID        string  `json:"user_id"`
	Email         *string `json:"email,omitempty"`
	Roles         *string `json:"roles,omitempty"`
	Permissions   *string `json:"permissions,omitempty"`
	CreatedAt     string  `json:"created_at"`
	ExpiresAt     string  `json:"expires_at"`
	Revoked       bool    `json:"revoked"`
}

type SentinelTypeItem struct {
	DaemonType  string              `json:"daemon_type"`
	DisplayName string              `json:"display_name"`
	Description string              `json:"description"`
	Fields      []SentinelTypeField `json:"fields"`
}

type SentinelTypeField struct {
	Key          string   `json:"key"`
	Label        string   `json:"label"`
	Type         string   `json:"type"`
	Required     bool     `json:"required"`
	DefaultValue any      `json:"default_value,omitempty"`
	Options      []string `json:"options,omitempty"`
	Placeholder  *string  `json:"placeholder,omitempty"`
	Description  *string  `json:"description,omitempty"`
}

type ServiceConnectionItem struct {
	ID           string         `json:"id"`
	Name         string         `json:"name"`
	PlatformType string         `json:"platform_type"`
	Config       map[string]any `json:"config"`
	CreatedAt    string         `json:"created_at"`
	UpdatedAt    string         `json:"updated_at"`
}

type CreateServiceConnectionRequest struct {
	Name         string         `json:"name"`
	PlatformType string         `json:"platformType"`
	Config       map[string]any `json:"config,omitempty"`
}

type UpdateServiceConnectionRequest struct {
	Name   *string        `json:"name,omitempty"`
	Config map[string]any `json:"config,omitempty"`
}

type SentinelsAPI struct{ client *Client }

func (a *SentinelsAPI) List() ([]SentinelItem, error) {
	var out []SentinelItem
	return out, a.client.get("/admin/sentinels", &out)
}

func (a *SentinelsAPI) Get(id string) (*SentinelItem, error) {
	var out SentinelItem
	return &out, a.client.get("/admin/sentinels/"+url.PathEscape(id), &out)
}

func (a *SentinelsAPI) Create(req CreateSentinelRequest) (*CreateSentinelResponse, error) {
	var out CreateSentinelResponse
	return &out, a.client.post("/admin/sentinels", req, &out)
}

func (a *SentinelsAPI) Update(id string, req UpdateSentinelRequest) (any, error) {
	var out any
	return out, a.client.put("/admin/sentinels/"+url.PathEscape(id), req, &out)
}

func (a *SentinelsAPI) Delete(id string) error {
	return a.client.delete("/admin/sentinels/" + url.PathEscape(id))
}

func (a *SentinelsAPI) RegenerateToken(id string) (any, error) {
	var out any
	return out, a.client.post("/admin/sentinels/"+url.PathEscape(id)+"/regenerate-token", nil, &out)
}

func (a *SentinelsAPI) Deploy(id string, config any) (*DeploySentinelResponse, error) {
	var out DeploySentinelResponse
	return &out, a.client.post("/admin/sentinels/"+url.PathEscape(id)+"/deploy", config, &out)
}

func (a *SentinelsAPI) Undeploy(id string) (any, error) {
	var out any
	return out, a.client.post("/admin/sentinels/"+url.PathEscape(id)+"/undeploy", nil, &out)
}

func (a *SentinelsAPI) Restart(id string) (*RestartSentinelResponse, error) {
	var out RestartSentinelResponse
	return &out, a.client.post("/admin/sentinels/"+url.PathEscape(id)+"/restart", nil, &out)
}

func (a *SentinelsAPI) Health(id string) (*SentinelHealthResponse, error) {
	var out SentinelHealthResponse
	return &out, a.client.get("/admin/sentinels/"+url.PathEscape(id)+"/health", &out)
}

func (a *SentinelsAPI) Heartbeat(id string) (any, error) {
	var out any
	return out, a.client.post("/admin/sentinels/"+url.PathEscape(id)+"/heartbeat", nil, &out)
}

func (a *SentinelsAPI) ListApplications(id string) ([]SentinelApplicationItem, error) {
	var out []SentinelApplicationItem
	return out, a.client.get("/admin/sentinels/"+url.PathEscape(id)+"/applications", &out)
}

func (a *SentinelsAPI) AttachApplication(id string, req AttachSentinelAppRequest) (*SentinelApplicationItem, error) {
	var out SentinelApplicationItem
	return &out, a.client.post("/admin/sentinels/"+url.PathEscape(id)+"/applications", req, &out)
}

func (a *SentinelsAPI) UpdateApplicationMediation(id, appID string, req any) (any, error) {
	var out any
	return out, a.client.put("/admin/sentinels/"+url.PathEscape(id)+"/applications/"+url.PathEscape(appID), req, &out)
}

func (a *SentinelsAPI) DetachApplication(id, appID string) error {
	return a.client.delete("/admin/sentinels/" + url.PathEscape(id) + "/applications/" + url.PathEscape(appID))
}

func (a *SentinelsAPI) ListResources(id string) ([]ResourceItem, error) {
	var out []ResourceItem
	return out, a.client.get("/admin/sentinels/"+url.PathEscape(id)+"/resources", &out)
}

func (a *SentinelsAPI) CreateResource(id string, req CreateResourceRequest) (*ResourceItem, error) {
	var out ResourceItem
	return &out, a.client.post("/admin/sentinels/"+url.PathEscape(id)+"/resources", req, &out)
}

func (a *SentinelsAPI) GetResource(id, rid string) (*ResourceItem, error) {
	var out ResourceItem
	return &out, a.client.get("/admin/sentinels/"+url.PathEscape(id)+"/resources/"+url.PathEscape(rid), &out)
}

func (a *SentinelsAPI) UpdateResource(id, rid string, req UpdateResourceRequest) (*ResourceItem, error) {
	var out ResourceItem
	return &out, a.client.put("/admin/sentinels/"+url.PathEscape(id)+"/resources/"+url.PathEscape(rid), req, &out)
}

func (a *SentinelsAPI) DeleteResource(id, rid string) error {
	return a.client.delete("/admin/sentinels/" + url.PathEscape(id) + "/resources/" + url.PathEscape(rid))
}

func (a *SentinelsAPI) ListSessions(id string) ([]SentinelSessionItem, error) {
	var out []SentinelSessionItem
	return out, a.client.get("/admin/sentinels/"+url.PathEscape(id)+"/sessions", &out)
}

func (a *SentinelsAPI) RevokeSession(id, sid string) (any, error) {
	var out any
	return out, a.client.post("/admin/sentinels/"+url.PathEscape(id)+"/sessions/"+url.PathEscape(sid)+"/revoke", nil, &out)
}

func (a *SentinelsAPI) ListTypes() ([]SentinelTypeItem, error) {
	var out []SentinelTypeItem
	return out, a.client.get("/admin/sentinel-types", &out)
}

func (a *SentinelsAPI) GetType(typeName string) (*SentinelTypeItem, error) {
	var out SentinelTypeItem
	return &out, a.client.get("/admin/sentinel-types/"+url.PathEscape(typeName), &out)
}

func (a *SentinelsAPI) ListServiceConnections() ([]ServiceConnectionItem, error) {
	var out []ServiceConnectionItem
	return out, a.client.get("/admin/service-connections", &out)
}

func (a *SentinelsAPI) CreateServiceConnection(req CreateServiceConnectionRequest) (*ServiceConnectionItem, error) {
	var out ServiceConnectionItem
	return &out, a.client.post("/admin/service-connections", req, &out)
}

func (a *SentinelsAPI) GetServiceConnection(id string) (*ServiceConnectionItem, error) {
	var out ServiceConnectionItem
	return &out, a.client.get("/admin/service-connections/"+url.PathEscape(id), &out)
}

func (a *SentinelsAPI) UpdateServiceConnection(id string, req UpdateServiceConnectionRequest) (*ServiceConnectionItem, error) {
	var out ServiceConnectionItem
	return &out, a.client.put("/admin/service-connections/"+url.PathEscape(id), req, &out)
}

func (a *SentinelsAPI) DeleteServiceConnection(id string) error {
	return a.client.delete("/admin/service-connections/" + url.PathEscape(id))
}
