package testutil

// TestingT is the subset of testing.TB used by FakeIDP.
type TestingT interface {
	Fatalf(format string, args ...interface{})
	Cleanup(f func())
}
