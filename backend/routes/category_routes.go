package routes

import (
	"mercadomio-backend/handlers"

	"github.com/gofiber/fiber/v2"
)

func SetupCategoryRoutes(app *fiber.App, categoryHandlers *handlers.CategoryHandlers) {
	// Category API routes
	app.Get("/api/categories", categoryHandlers.GetCategories)
	app.Get("/api/categories/search", categoryHandlers.SearchCategoryByName)
	app.Post("/api/categories", categoryHandlers.CreateCategory)
	app.Put("/api/categories/:id", categoryHandlers.UpdateCategory)
	app.Delete("/api/categories/:id", categoryHandlers.DeleteCategory)
}
