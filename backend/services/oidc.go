package services

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/MicahParks/keyfunc/v3"
	"github.com/golang-jwt/jwt/v5"
)

const adminGroup = "mercadomio-admin"

// OidcClaims represents the identity claims issued by userbrew.
// It also tolerates a local "userId" claim (used by the local auth service
// token) so either token shape resolves to a userID.
type OidcClaims struct {
	Sub    string   `json:"sub"`
	UserID string   `json:"userId"`
	Email  string   `json:"email"`
	Name   string   `json:"name"`
	Roles  []string `json:"roles,omitempty"`
	Groups []string `json:"groups,omitempty"`
	jwt.RegisteredClaims
}

// AudienceMatches reports whether the token audience intersects the accepted set.
func (c *OidcClaims) AudienceMatches(accepted []string) bool {
	for _, aud := range c.Audience {
		for _, a := range accepted {
			if aud == a {
				return true
			}
		}
	}
	return false
}

// IsAdmin reports whether the token carries the mercadomio-admin group.
func (c *OidcClaims) IsAdmin() bool {
	for _, r := range c.Roles {
		if r == adminGroup {
			return true
		}
	}
	for _, g := range c.Groups {
		if g == adminGroup {
			return true
		}
	}
	return false
}

// OidcService validates OIDC access tokens issued by userbrew using its JWKS.
type OidcService struct {
	issuer    string
	audiences []string
	keyFunc   keyfunc.Keyfunc
}

// NewOidcService fetches the provider discovery document and builds a JWKS-backed
// key function that refreshes keys when an unknown KID is seen. Tokens are
// accepted when their audience includes any of the configured client IDs.
func NewOidcService(issuer string, audiences []string) (*OidcService, error) {
	discoveryURL := fmt.Sprintf("%s/.well-known/openid-configuration", issuer)
	return NewOidcServiceAt(discoveryURL, issuer, audiences)
}

// NewOidcServiceAt behaves like NewOidcService but fetches discovery from a
// separate URL, which lets the backend reach the IdP over an internal network
// while still validating tokens against the public issuer value.
func NewOidcServiceAt(discoveryURL, issuer string, audiences []string) (*OidcService, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Get(discoveryURL)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch OIDC discovery: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("OIDC discovery returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return nil, fmt.Errorf("failed to read OIDC discovery: %w", err)
	}

	var doc struct {
		JWKSURI string `json:"jwks_uri"`
	}
	if err := json.Unmarshal(body, &doc); err != nil {
		return nil, fmt.Errorf("failed to parse OIDC discovery: %w", err)
	}
	if doc.JWKSURI == "" {
		return nil, fmt.Errorf("OIDC discovery has no jwks_uri")
	}

	kf, err := keyfunc.NewDefaultCtx(context.Background(), []string{doc.JWKSURI})
	if err != nil {
		return nil, fmt.Errorf("failed to create JWKS keyfunc: %w", err)
	}

	return &OidcService{issuer: issuer, audiences: audiences, keyFunc: kf}, nil
}

// ValidateToken verifies signature, expiry, issuer and audience of an access token.
func (s *OidcService) ValidateToken(tokenString string) (*OidcClaims, error) {
	if s == nil || s.keyFunc == nil {
		return nil, fmt.Errorf("token validation unavailable (IdP not configured)")
	}
	parser := jwt.NewParser(
		jwt.WithValidMethods([]string{"RS256"}),
		jwt.WithIssuer(s.issuer),
		jwt.WithExpirationRequired(),
	)

	token, err := parser.ParseWithClaims(tokenString, &OidcClaims{}, s.keyFunc.Keyfunc)
	if err != nil {
		return nil, fmt.Errorf("invalid token: %w", err)
	}

	claims, ok := token.Claims.(*OidcClaims)
	if !ok || !token.Valid {
		return nil, fmt.Errorf("invalid token claims")
	}
	if claims.Sub == "" {
		return nil, fmt.Errorf("token has empty sub claim")
	}
	if !claims.AudienceMatches(s.audiences) {
		return nil, fmt.Errorf("token audience not accepted")
	}

	return claims, nil
}
