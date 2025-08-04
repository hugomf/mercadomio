package routes

import (
	"mercadomio-backend/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupAnalyticsRoutes configures all analytics-related routes
func SetupAnalyticsRoutes(app *fiber.App, analyticsHandlers *handlers.AnalyticsHandlers) {
	// Analytics API routes
	app.Get("/api/analytics/carts/abandoned", analyticsHandlers.GetAbandonedCartAnalytics)
	app.Get("/api/analytics/carts/conversions", analyticsHandlers.GetConversionAnalytics)
	app.Get("/api/analytics/products/views", analyticsHandlers.GetProductViews)
	app.Get("/api/analytics/search", analyticsHandlers.GetSearchAnalytics)
}
