package imageurl

import "regexp"

var uuidPattern = regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`)

const defaultVariant = "card"

// Resolve converts a stored image reference into a servable URL.
//
// An empty reference stays empty, a legacy full http(s) URL passes through
// unchanged, and an imgvault UUID is rewritten to this backend's variant
// proxy so the storefront never talks to imgvault directly.
func Resolve(stored, baseURL string) string {
	if stored == "" || !uuidPattern.MatchString(stored) {
		return stored
	}
	return baseURL + "/api/imgvault/images/" + stored + "/variant/" + defaultVariant
}