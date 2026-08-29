package routes

import (
	"mercadomio-backend/handlers"
	"mercadomio-backend/middleware"
	"mercadomio-backend/services"

	"github.com/gofiber/fiber/v2"
)

// SetupAuthRoutes configures authentication routes. Registration and login
// happen at the userbrew IdP; this API only accepts its tokens.
func SetupAuthRoutes(app *fiber.App, authHandlers *handlers.AuthHandlers, oidc *services.OidcService) {
	auth := app.Group("/api/auth")

	// Protected routes (require authentication)
	auth.Use(middleware.AuthMiddleware(oidc))
	auth.Get("/profile", authHandlers.GetProfile)
	auth.Put("/profile", authHandlers.UpdateProfile)
	auth.Get("/verify", authHandlers.VerifyToken)

	// User shopping profile routes
	auth.Get("/addresses", authHandlers.GetUserAddresses)
	auth.Post("/addresses", authHandlers.CreateUserAddress)
	auth.Get("/payment-methods", authHandlers.GetUserPaymentMethods)
	auth.Post("/payment-methods", authHandlers.CreateUserPaymentMethod)
	auth.Get("/wishlist", authHandlers.GetUserWishlist)
	auth.Post("/wishlist/:productId", authHandlers.AddToWishlist)
	auth.Delete("/wishlist/:productId", authHandlers.RemoveFromWishlist)
}
