package middleware

import (
	"strings"

	"mercadomio-backend/services"

	"github.com/gofiber/fiber/v2"
)

const bearerPrefix = "Bearer "

// extractBearerToken returns the raw token from an Authorization header.
func extractBearerToken(c *fiber.Ctx) (string, bool) {
	header := c.Get("Authorization")
	if header == "" || !strings.HasPrefix(header, bearerPrefix) {
		return "", false
	}
	token := strings.TrimSpace(strings.TrimPrefix(header, bearerPrefix))
	if token == "" {
		return "", false
	}
	return token, true
}

// setIdentityLocals stores the validated identity for downstream handlers.
// Prefers the OIDC "sub" claim, but falls back to a local "userId" claim so
// tokens issued by the local auth service (which carry userId) also work.
func setIdentityLocals(c *fiber.Ctx, claims *services.OidcClaims) {
	userID := claims.Sub
	if userID == "" {
		userID = claims.UserID
	}
	c.Locals("userID", userID)
	c.Locals("userEmail", claims.Email)
	c.Locals("userName", claims.Name)
	c.Locals("isAdmin", claims.IsAdmin())
}

// AuthMiddleware authenticates requests using OIDC tokens issued by userbrew.
func AuthMiddleware(oidc *services.OidcService) fiber.Handler {
	return func(c *fiber.Ctx) error {
		token, ok := extractBearerToken(c)
		if !ok {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Authorization header is required",
			})
		}

		claims, err := oidc.ValidateToken(token)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Invalid or expired token",
			})
		}

		setIdentityLocals(c, claims)
		return c.Next()
	}
}

// OptionalAuthMiddleware attaches identity when a valid token is present,
// but never blocks the request.
func OptionalAuthMiddleware(oidc *services.OidcService) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if token, ok := extractBearerToken(c); ok {
			if claims, err := oidc.ValidateToken(token); err == nil {
				setIdentityLocals(c, claims)
			}
		}
		return c.Next()
	}
}

// AdminMiddleware requires a valid token carrying the mercadomio-admin group.
func AdminMiddleware(oidc *services.OidcService) fiber.Handler {
	return func(c *fiber.Ctx) error {
		token, ok := extractBearerToken(c)
		if !ok {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Authorization header is required",
			})
		}

		claims, err := oidc.ValidateToken(token)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Invalid or expired token",
			})
		}

		if !claims.IsAdmin() {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"success": false,
				"message": "Admin access required",
			})
		}

		setIdentityLocals(c, claims)
		return c.Next()
	}
}
