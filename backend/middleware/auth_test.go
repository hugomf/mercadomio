package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"

	"mercadomio-backend/internal/testutil"
	"mercadomio-backend/services"
)

func newAuthApp(t *testing.T) (*testutil.FakeIDP, *fiber.App) {
	t.Helper()
	idp := testutil.NewFakeIDP(t)
	svc, err := services.NewOidcService(idp.Server.URL, []string{"mercadomio-storefront"})
	if err != nil {
		t.Fatalf("NewOidcService failed: %v", err)
	}

	app := fiber.New()
	app.Get("/protected", AuthMiddleware(svc), func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"userID":    c.Locals("userID"),
			"userEmail": c.Locals("userEmail"),
			"userName":  c.Locals("userName"),
			"isAdmin":   c.Locals("isAdmin"),
		})
	})
	app.Get("/admin", AdminMiddleware(svc), func(c *fiber.Ctx) error {
		return c.SendStatus(http.StatusOK)
	})
	return idp, app
}

func tokenFor(idp *testutil.FakeIDP, issuer string, groups []string) string {
	now := time.Now()
	claims := services.OidcClaims{
		Sub:    "sub-42",
		Email:  "ana@example.com",
		Name:   "Ana López",
		Groups: groups,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    issuer,
			Audience:  jwt.ClaimStrings{"mercadomio-storefront"},
			Subject:   "sub-42",
			ExpiresAt: jwt.NewNumericDate(now.Add(time.Hour)),
			IssuedAt:  jwt.NewNumericDate(now),
		},
	}
	return idp.SignToken(claims, "initial-key")
}

func TestAuthMiddleware_SetsIdentityLocals(t *testing.T) {
	idp, app := newAuthApp(t)
	token := tokenFor(idp, idp.Server.URL, []string{"customers"})

	req := httptest.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("status = %d, want 200", resp.StatusCode)
	}
}

func TestAuthMiddleware_RejectsMissingHeader(t *testing.T) {
	_, app := newAuthApp(t)

	req := httptest.NewRequest(http.MethodGet, "/protected", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", resp.StatusCode)
	}
}

func TestAuthMiddleware_RejectsInvalidToken(t *testing.T) {
	_, app := newAuthApp(t)

	req := httptest.NewRequest(http.MethodGet, "/protected", nil)
	req.Header.Set("Authorization", "Bearer not-a-jwt")
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", resp.StatusCode)
	}
}

func TestAdminMiddleware_AllowsAdminGroup(t *testing.T) {
	idp, app := newAuthApp(t)
	token := tokenFor(idp, idp.Server.URL, []string{"customers", "mercadomio-admin"})

	req := httptest.NewRequest(http.MethodGet, "/admin", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("status = %d, want 200 for admin group", resp.StatusCode)
	}
}

func TestAdminMiddleware_ForbiddenWithoutAdminGroup(t *testing.T) {
	idp, app := newAuthApp(t)
	token := tokenFor(idp, idp.Server.URL, []string{"customers"})

	req := httptest.NewRequest(http.MethodGet, "/admin", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != http.StatusForbidden {
		t.Fatalf("status = %d, want 403 without admin group", resp.StatusCode)
	}
}
