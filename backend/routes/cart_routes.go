package routes

import (
	"mercadomio-backend/handlers"
	"mercadomio-backend/middleware"
	"mercadomio-backend/services"

	"github.com/gofiber/fiber/v2"
)

// SetupCartRoutes configures all cart-related routes with authentication
func SetupCartRoutes(app *fiber.App, cartHandlers *handlers.CartHandlers, authService *services.AuthService) {
	// Public routes (guest carts): reads and writes work off the cartId alone,
	// so authentication is optional. When a valid token is present, userID is
	// still populated in Locals for handlers that want it.
	app.Get("/api/cart/:cartId", middleware.OptionalAuthMiddleware(authService), cartHandlers.GetCart)
	app.Post("/api/cart/:cartId/items", middleware.OptionalAuthMiddleware(authService), cartHandlers.AddToCart)
	app.Put("/api/cart/:cartId/items/:productId", middleware.OptionalAuthMiddleware(authService), cartHandlers.UpdateCartItem)
	app.Delete("/api/cart/:cartId/items/:productId", middleware.OptionalAuthMiddleware(authService), cartHandlers.RemoveFromCart)
	app.Post("/api/cart/merge", middleware.OptionalAuthMiddleware(authService), cartHandlers.MergeCarts)
}
