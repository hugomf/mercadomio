package userbrew

import "net/url"

type FlowItem struct {
	ID          string  `json:"id"`
	Slug        string  `json:"slug"`
	Title       string  `json:"title"`
	Designation string  `json:"designation"`
	Description *string `json:"description,omitempty"`
	Enabled     bool    `json:"enabled"`
	CreatedAt   string  `json:"created_at"`
	UpdatedAt   string  `json:"updated_at"`
}

type CreateFlowRequest struct {
	Slug        string  `json:"slug"`
	Title       string  `json:"title"`
	Designation string  `json:"designation"`
	Description *string `json:"description,omitempty"`
	Enabled     *bool   `json:"enabled,omitempty"`
}

type UpdateFlowRequest struct {
	Title       *string `json:"title,omitempty"`
	Slug        *string `json:"slug,omitempty"`
	Description *string `json:"description,omitempty"`
	Enabled     *bool   `json:"enabled,omitempty"`
	Designation *string `json:"designation,omitempty"`
}

type BindingItem struct {
	ID                 string  `json:"id"`
	FlowID             string  `json:"flow_id"`
	StageID            *string `json:"stage_id,omitempty"`
	SubFlowID          *string `json:"sub_flow_id,omitempty"`
	Order              int64   `json:"order"`
	Requirement        string  `json:"requirement"`
	EvaluateOnSuccess  bool    `json:"evaluate_on_success"`
	ReEvaluatePolicies bool    `json:"re_evaluate_policies"`
	PolicyID           *string `json:"policy_id,omitempty"`
	PolicyMode         *string `json:"policy_mode,omitempty"`
	CreatedAt          string  `json:"created_at"`
}

type CreateBindingRequest struct {
	StageID            *string `json:"stage_id,omitempty"`
	SubFlowID          *string `json:"sub_flow_id,omitempty"`
	SortOrder          *int64  `json:"sort_order,omitempty"`
	Requirement        *string `json:"requirement,omitempty"`
	EvaluateOnSuccess  *bool   `json:"evaluate_on_success,omitempty"`
	ReEvaluatePolicies *bool   `json:"re_evaluate_policies,omitempty"`
	PolicyID           *string `json:"policy_id,omitempty"`
	PolicyMode         *string `json:"policy_mode,omitempty"`
}

type UpdateBindingRequest struct {
	StageID            *string `json:"stage_id,omitempty"`
	SubFlowID          *string `json:"sub_flow_id,omitempty"`
	SortOrder          *int64  `json:"sort_order,omitempty"`
	Requirement        *string `json:"requirement,omitempty"`
	EvaluateOnSuccess  *bool   `json:"evaluate_on_success,omitempty"`
	ReEvaluatePolicies *bool   `json:"re_evaluate_policies,omitempty"`
	PolicyID           *string `json:"policy_id,omitempty"`
	PolicyMode         *string `json:"policy_mode,omitempty"`
}

type FlowsAPI struct{ client *Client }

func (a *FlowsAPI) List() ([]FlowItem, error) {
	var out []FlowItem
	return out, a.client.get("/admin/flows", &out)
}

func (a *FlowsAPI) Get(id string) (*FlowItem, error) {
	var out FlowItem
	return &out, a.client.get("/admin/flows/"+url.PathEscape(id), &out)
}

func (a *FlowsAPI) Create(req CreateFlowRequest) (*FlowItem, error) {
	var out FlowItem
	return &out, a.client.post("/admin/flows", req, &out)
}

func (a *FlowsAPI) Update(id string, req UpdateFlowRequest) (*FlowItem, error) {
	var out FlowItem
	return &out, a.client.put("/admin/flows/"+url.PathEscape(id), req, &out)
}

func (a *FlowsAPI) Delete(id string) error {
	return a.client.delete("/admin/flows/" + url.PathEscape(id))
}

func (a *FlowsAPI) ListBindings(flowID string) ([]BindingItem, error) {
	var out []BindingItem
	return out, a.client.get("/admin/flows/"+url.PathEscape(flowID)+"/bindings", &out)
}

func (a *FlowsAPI) CreateBinding(flowID string, req CreateBindingRequest) (*BindingItem, error) {
	var out BindingItem
	return &out, a.client.post("/admin/flows/"+url.PathEscape(flowID)+"/bindings", req, &out)
}

func (a *FlowsAPI) UpdateBinding(flowID, bindingID string, req UpdateBindingRequest) (*BindingItem, error) {
	var out BindingItem
	return &out, a.client.put("/admin/flows/"+url.PathEscape(flowID)+"/bindings/"+url.PathEscape(bindingID), req, &out)
}

func (a *FlowsAPI) DeleteBinding(flowID, bindingID string) error {
	return a.client.delete("/admin/flows/" + url.PathEscape(flowID) + "/bindings/" + url.PathEscape(bindingID))
}
