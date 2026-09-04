package userbrew

import "fmt"

type APIError struct {
	Status  int
	Message string
}

func (e *APIError) Error() string {
	return fmt.Sprintf("API error (%d): %s", e.Status, e.Message)
}
