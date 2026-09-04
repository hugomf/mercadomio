package userbrew

import "net/url"

type StageItem struct {
	ID        string         `json:"id"`
	Name      string         `json:"name"`
	StageType string         `json:"stage_type"`
	Config    map[string]any `json:"config"`
	CreatedAt string         `json:"created_at"`
	UpdatedAt string         `json:"updated_at"`
}

type CreateStageRequest struct {
	Name      string         `json:"name"`
	StageType string         `json:"stage_type"`
	Config    map[string]any `json:"config,omitempty"`
}

type UpdateStageRequest struct {
	Name      *string        `json:"name,omitempty"`
	StageType *string        `json:"stage_type,omitempty"`
	Config    map[string]any `json:"config,omitempty"`
}

type StagesAPI struct{ client *Client }

func (a *StagesAPI) List() ([]StageItem, error) {
	var out []StageItem
	return out, a.client.get("/admin/stages", &out)
}

func (a *StagesAPI) Get(id string) (*StageItem, error) {
	var out StageItem
	return &out, a.client.get("/admin/stages/"+url.PathEscape(id), &out)
}

func (a *StagesAPI) Create(req CreateStageRequest) (*StageItem, error) {
	var out StageItem
	return &out, a.client.post("/admin/stages", req, &out)
}

func (a *StagesAPI) Update(id string, req UpdateStageRequest) (*StageItem, error) {
	var out StageItem
	return &out, a.client.put("/admin/stages/"+url.PathEscape(id), req, &out)
}

func (a *StagesAPI) Delete(id string) error {
	return a.client.delete("/admin/stages/" + url.PathEscape(id))
}
