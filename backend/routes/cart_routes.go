package routes

import (
	"mercadomio-backend/handlers"
	"mercadomio-backend/middleware"
	"mercadomio-backend/services"

	"github.com/gofiber/fiber/v2"
)

// SetupCartRoutes configures all cart-related routes with authentication
func SetupCartRoutes(app *fiber.App, cartHandlers *handlers.CartHandlers, authService *services.AuthService) {
	// Public routes (guest carts)
	app.Get("/api/cart/:cartId", middleware.OptionalAuthMiddleware(authService), cartHandlers.GetCart)

	// Protected routes (require authentication)
	auth := app.Group("/api/cart", middleware.AuthMiddleware(authService))
	auth.Post("/:cartId/items", cartHandlers.AddToCart)
	auth.Put("/:cartId/items/:productId", cartHandlers.UpdateCartItem)
	auth.Delete("/:cartId/items/:productId", cartHandlers.RemoveFromCart)
	auth.Post("/merge", cartHandlers.MergeCarts)
}
