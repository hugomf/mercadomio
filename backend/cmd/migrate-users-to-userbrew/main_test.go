package main

import "testing"

func TestUsernameFromEmail(t *testing.T) {
	cases := []struct{ in, want string }{
		{"Carlos.Perez@Example.com", "carlos.perez"},
		{"maria_gomez@mail.mx", "maria.gomez"}, // underscore dropped
		{"  juan@mail.mx  ", "juan"},
		{"@@@", "user"},
	}
	for _, c := range cases {
		if got := usernameFromEmail(c.in); got != c.want {
			t.Errorf("usernameFromEmail(%q) = %q, want %q", c.in, got, c.want)
		}
	}
}
