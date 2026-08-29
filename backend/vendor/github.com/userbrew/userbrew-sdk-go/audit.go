package userbrew

import (
	"fmt"
	"net/url"
)

type AuditLogEntry struct {
	ID        string         `json:"id"`
	Timestamp int64          `json:"timestamp"`
	EventType string         `json:"event_type"`
	UserID    *string        `json:"user_id,omitempty"`
	UserEmail *string        `json:"user_email,omitempty"`
	IPAddress *string        `json:"ip_address,omitempty"`
	UserAgent *string        `json:"user_agent,omitempty"`
	Details   map[string]any `json:"details"`
}

type AuditLogQuery struct {
	EventType *string `json:"event_type,omitempty"`
	UserID    *string `json:"user_id,omitempty"`
	StartDate *string `json:"start_date,omitempty"`
	EndDate   *string `json:"end_date,omitempty"`
	PageSize  *int64  `json:"page_size,omitempty"`
	Page      *int64  `json:"page,omitempty"`
}

type AuditAPI struct{ client *Client }

func (a *AuditAPI) List(query *AuditLogQuery) ([]AuditLogEntry, error) {
	q := url.Values{}
	if query != nil {
		if query.EventType != nil { q.Set("event_type", *query.EventType) }
		if query.UserID != nil { q.Set("user_id", *query.UserID) }
		if query.StartDate != nil { q.Set("start_date", *query.StartDate) }
		if query.EndDate != nil { q.Set("end_date", *query.EndDate) }
		if query.PageSize != nil { q.Set("page_size", fmt.Sprintf("%d", *query.PageSize)) }
		if query.Page != nil { q.Set("page", fmt.Sprintf("%d", *query.Page)) }
	}
	path := "/admin/audit-log"
	if s := q.Encode(); s != "" { path += "?" + s }
	var out []AuditLogEntry
	return out, a.client.get(path, &out)
}
