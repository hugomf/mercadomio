package userbrew

type AdminStats struct {
	TotalUsers          int64 `json:"total_users"`
	ActiveUsers         int64 `json:"active_users"`
	LockedUsers         int64 `json:"locked_users"`
	PendingVerification int64 `json:"pending_verification"`
	TotalRoles          int64 `json:"total_roles"`
	ActiveSessions      int64 `json:"active_sessions"`
}

type StatsAPI struct{ client *Client }

func (a *StatsAPI) Get() (*AdminStats, error) {
	var out AdminStats
	return &out, a.client.get("/admin/stats", &out)
}
