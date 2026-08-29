package services

import (
	"crypto/rand"
	"crypto/rsa"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"mercadomio-backend/internal/testutil"
)

func TestValidateToken_AcceptsValidToken(t *testing.T) {
	idp := testutil.NewFakeIDP(t)
	svc, err := NewOidcService(idp.Server.URL, []string{"mercadomio-storefront"})
	if err != nil {
		t.Fatalf("NewOidcService failed: %v", err)
	}

	claims := validClaims(idp.Server.URL)
	token := idp.SignToken(claims, "initial-key")

	got, err := svc.ValidateToken(token)
	if err != nil {
		t.Fatalf("expected valid token, got error: %v", err)
	}
	if got.Sub != "userbrew-sub-123" {
		t.Errorf("Sub = %q, want %q", got.Sub, "userbrew-sub-123")
	}
	if got.Email != "carlos@example.com" {
		t.Errorf("Email = %q, want %q", got.Email, "carlos@example.com")
	}
	if got.Name != "Carlos Pérez" {
		t.Errorf("Name = %q, want %q", got.Name, "Carlos Pérez")
	}
}

func TestNewOidcServiceAt_SeparatesDiscoveryFromIssuer(t *testing.T) {
	idp := testutil.NewFakeIDP(t)
	// Discovery happens through a proxy (stand-in for an internal network
	// address); the expected issuer stays the public URL in token claims.
	proxy := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp, err := http.Get(idp.Server.URL + r.URL.RequestURI())
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadGateway)
			return
		}
		defer resp.Body.Close()
		w.Header().Set("Content-Type", resp.Header.Get("Content-Type"))
		w.WriteHeader(resp.StatusCode)
		io.Copy(w, resp.Body)
	}))
	defer proxy.Close()

	svc, err := NewOidcServiceAt(
		fmt.Sprintf("%s/.well-known/openid-configuration", proxy.URL),
		idp.Server.URL,
		[]string{"mercadomio-storefront"},
	)
	if err != nil {
		t.Fatalf("NewOidcServiceAt failed: %v", err)
	}

	token := idp.SignToken(validClaims(idp.Server.URL), "initial-key")
	if _, err := svc.ValidateToken(token); err != nil {
		t.Fatalf("expected token validated via proxied discovery, got: %v", err)
	}
}

func TestValidateToken_RejectsWrongAudience(t *testing.T) {
	idp := testutil.NewFakeIDP(t)
	svc, err := NewOidcService(idp.Server.URL, []string{"mercadomio-storefront"})
	if err != nil {
		t.Fatalf("NewOidcService failed: %v", err)
	}

	claims := validClaims(idp.Server.URL)
	claims.Audience = jwt.ClaimStrings{"otra-app"}
	token := idp.SignToken(claims, "initial-key")

	if _, err := svc.ValidateToken(token); err == nil {
		t.Fatal("expected rejection for wrong audience, got none")
	}
}

func TestValidateToken_AcceptsAnyConfiguredAudience(t *testing.T) {
	idp := testutil.NewFakeIDP(t)
	svc, err := NewOidcService(idp.Server.URL, []string{"mercadomio-storefront", "mercadomio-admin"})
	if err != nil {
		t.Fatalf("NewOidcService failed: %v", err)
	}

	adminClaims := validClaims(idp.Server.URL)
	adminClaims.Audience = jwt.ClaimStrings{"mercadomio-admin"}
	token := idp.SignToken(adminClaims, "initial-key")

	if _, err := svc.ValidateToken(token); err != nil {
		t.Fatalf("expected admin-audience token accepted, got: %v", err)
	}
}

func TestValidateToken_RejectsExpiredToken(t *testing.T) {
	idp := testutil.NewFakeIDP(t)
	svc, err := NewOidcService(idp.Server.URL, []string{"mercadomio-storefront"})
	if err != nil {
		t.Fatalf("NewOidcService failed: %v", err)
	}

	claims := validClaims(idp.Server.URL)
	claims.ExpiresAt = jwt.NewNumericDate(time.Now().Add(-time.Hour))
	token := idp.SignToken(claims, "initial-key")

	if _, err := svc.ValidateToken(token); err == nil {
		t.Fatal("expected rejection for expired token, got none")
	}
}

func TestValidateToken_RejectsWrongIssuer(t *testing.T) {
	idp := testutil.NewFakeIDP(t)
	svc, err := NewOidcService(idp.Server.URL, []string{"mercadomio-storefront"})
	if err != nil {
		t.Fatalf("NewOidcService failed: %v", err)
	}

	claims := validClaims("https://evil.example.com")
	token := idp.SignToken(claims, "initial-key")

	if _, err := svc.ValidateToken(token); err == nil {
		t.Fatal("expected rejection for wrong issuer, got none")
	}
}

func TestValidateToken_RefreshesKeysOnUnknownKID(t *testing.T) {
	idp := testutil.NewFakeIDP(t)

	newKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("failed to generate second RSA key: %v", err)
	}

	svc, err := NewOidcService(idp.Server.URL, []string{"mercadomio-storefront"})
	if err != nil {
		t.Fatalf("NewOidcService failed: %v", err)
	}

	// IdP rotates: publishes a new key under a fresh KID.
	idp.PublishKey("rotated-key", &newKey.PublicKey)

	claims := validClaims(idp.Server.URL)
	token := idp.SignTokenWithKey(claims, "rotated-key", newKey)

	if _, err := svc.ValidateToken(token); err != nil {
		t.Fatalf("expected JWKS refresh to accept rotated key, got: %v", err)
	}
}

func TestOidcClaims_IsAdmin(t *testing.T) {
	claims := validClaims("https://idp.example.com")
	if claims.IsAdmin() {
		t.Fatal("expected non-admin claims to report IsAdmin=false")
	}

	claims.Roles = []string{"customers", "mercadomio-admin"}
	if !claims.IsAdmin() {
		t.Fatal("expected mercadomio-admin role to report IsAdmin=true")
	}
}

func validClaims(issuer string) OidcClaims {
	now := time.Now()
	return OidcClaims{
		Sub:    "userbrew-sub-123",
		Email:  "carlos@example.com",
		Name:   "Carlos Pérez",
		Groups: []string{"customers"},
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    issuer,
			Audience:  jwt.ClaimStrings{"mercadomio-storefront"},
			ExpiresAt: jwt.NewNumericDate(now.Add(time.Hour)),
			IssuedAt:  jwt.NewNumericDate(now),
			Subject:   "userbrew-sub-123",
		},
	}
}
