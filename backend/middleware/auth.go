package middleware

import (
	"mercadomio-backend/services"
	"strings"

	"github.com/gofiber/fiber/v2"
)

// AuthMiddleware authenticates requests using JWT tokens
func AuthMiddleware(authService *services.AuthService) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")

		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Authorization header is required",
			})
		}

		// Extract token from "Bearer <token>" format
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Invalid authorization header format",
			})
		}

		token := tokenParts[1]

		// Validate token
		claims, err := authService.ValidateToken(token)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Invalid or expired token",
			})
		}

		// Store user info in locals for use in handlers
		c.Locals("userID", claims.UserID)
		c.Locals("userEmail", claims.Email)
		c.Locals("userType", claims.Type)

		return c.Next()
	}
}

// OptionalAuthMiddleware allows requests with or without authentication
func OptionalAuthMiddleware(authService *services.AuthService) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")

		if authHeader != "" {
			// Extract token from "Bearer <token>" format
			tokenParts := strings.Split(authHeader, " ")
			if len(tokenParts) == 2 && tokenParts[0] == "Bearer" {
				token := tokenParts[1]

				// Validate token (but don't fail if invalid)
				claims, err := authService.ValidateToken(token)
				if err == nil {
					// Store user info in locals for use in handlers
					c.Locals("userID", claims.UserID)
					c.Locals("userEmail", claims.Email)
					c.Locals("userType", claims.Type)
				}
			}
		}

		return c.Next()
	}
}
