package routes

import (
	"mercadomio-backend/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupCartRoutes configures all cart-related routes
func SetupCartRoutes(app *fiber.App, cartHandlers *handlers.CartHandlers) {
	// Cart API routes
	app.Get("/api/cart/:cartId", cartHandlers.GetCart)
	app.Post("/api/cart/:cartId/items", cartHandlers.AddToCart)
	app.Put("/api/cart/:cartId/items/:productId", cartHandlers.UpdateCartItem)
	app.Delete("/api/cart/:cartId/items/:productId", cartHandlers.RemoveFromCart)
	app.Post("/api/cart/merge", cartHandlers.MergeCarts)
}
