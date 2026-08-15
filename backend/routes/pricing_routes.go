package routes

import (
	"github.com/gofiber/fiber/v2"

	"mercadomio-backend/handlers"
)

// SetupPricingRoutes registers price-set, price-schedule and price-history admin endpoints.
func SetupPricingRoutes(app *fiber.App, pricingHandlers *handlers.PricingHandlers) {
	admin := app.Group("/api/pricing")

	// Price sets
	admin.Get("/price-sets", pricingHandlers.ListPriceSets)
	admin.Post("/price-sets", pricingHandlers.CreatePriceSet)
	admin.Put("/price-sets/:id", pricingHandlers.UpdatePriceSet)
	admin.Delete("/price-sets/:id", pricingHandlers.DeletePriceSet)

	// Price schedules
	admin.Get("/price-schedules", pricingHandlers.ListPriceSchedules)
	admin.Post("/price-schedules", pricingHandlers.CreatePriceSchedule)
	admin.Put("/price-schedules/:id", pricingHandlers.UpdatePriceSchedule)
	admin.Delete("/price-schedules/:id", pricingHandlers.DeletePriceSchedule)

	// Price history
	admin.Get("/price-history", pricingHandlers.ListPriceHistory)

	// Resolution preview
	admin.Post("/resolve", pricingHandlers.ResolvePricesPreview)
}