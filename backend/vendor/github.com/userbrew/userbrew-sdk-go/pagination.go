package userbrew

type PaginatedUsers[T any] struct {
	Users   []T   `json:"users"`
	Total   int64 `json:"total"`
	Page    int64 `json:"page"`
	PerPage int64 `json:"per_page"`
}
