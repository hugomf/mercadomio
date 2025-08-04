package routes

import (
	"mercadomio-backend/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupProductRoutes configures all product-related routes
func SetupProductRoutes(app *fiber.App, productHandlers *handlers.ProductHandlers) {
	// Product API routes
	app.Get("/api/products", productHandlers.GetProducts)
	app.Get("/api/products/:id", productHandlers.GetProduct)
	app.Post("/api/products", productHandlers.CreateProduct)
	app.Put("/api/products/:id", productHandlers.UpdateProduct)
	app.Delete("/api/products/:id", productHandlers.DeleteProduct)

	// Variants endpoint
	app.Get("/api/variants", productHandlers.GetVariants)
}
