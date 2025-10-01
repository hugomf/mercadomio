package routes

import (
	"mercadomio-backend/handlers"
	"mercadomio-backend/middleware"

	"github.com/gofiber/fiber/v2"
)

// SetupAuthRoutes configures authentication routes
func SetupAuthRoutes(app *fiber.App, authHandlers *handlers.AuthHandlers) {
	auth := app.Group("/api/auth")

	// Public routes
	auth.Post("/register", authHandlers.Register)
	auth.Post("/login", authHandlers.Login)

	// Protected routes (require authentication)
	auth.Use(middleware.AuthMiddleware(authHandlers.AuthService()))
	auth.Get("/profile", authHandlers.GetProfile)
	auth.Put("/profile", authHandlers.UpdateProfile)
	auth.Get("/verify", authHandlers.VerifyToken)
}
