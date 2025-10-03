package routes

import (
	"mercadomio-backend/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupOrderRoutes configures all order-related routes
func SetupOrderRoutes(app *fiber.App, orderHandlers *handlers.OrderHandlers) {
	// Order API routes
	app.Get("/api/orders", orderHandlers.GetUserOrders)                // Get user orders
	app.Post("/api/orders", orderHandlers.CreateOrder)                 // Create new order
	app.Get("/api/orders/:id", orderHandlers.GetOrder)                 // Get specific order
	app.Put("/api/orders/:id/status", orderHandlers.UpdateOrderStatus) // Update order status
	app.Post("/api/orders/:id/payment", orderHandlers.AddPaymentInfo)  // Add payment info
}
