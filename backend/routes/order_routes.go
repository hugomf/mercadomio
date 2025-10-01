package routes

import (
	"mercadomio-backend/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupOrderRoutes configures the order-related routes
func SetupOrderRoutes(app *fiber.App, orderHandlers *handlers.OrderHandlers) {
	// Order routes group with authentication
	v1 := app.Group("/api")
	v1.Use(func(c *fiber.Ctx) error {
		// Placeholder for auth middleware - will be replaced with proper auth
		return c.Next()
	})

	// Order management routes
	orders := v1.Group("/orders")

	// Create order from cart
	orders.Post("/", orderHandlers.CreateOrder)

	// Get user order history (paginated)
	orders.Get("/", orderHandlers.GetUserOrders)

	// Get specific order details
	orders.Get("/:id", orderHandlers.GetOrder)

	// Update order status (admin function - should have admin check in production)
	orders.Put("/:id/status", orderHandlers.UpdateOrderStatus)

	// Add payment information
	orders.Post("/:id/payment", orderHandlers.AddPaymentInfo)

	// Order statistics (admin function)
	orders.Get("/admin/stats", orderHandlers.GetOrderStats)
}
