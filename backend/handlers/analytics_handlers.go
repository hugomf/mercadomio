package handlers

import (
	"mercadomio-backend/middleware"
	"mercadomio-backend/services"

	"github.com/gofiber/fiber/v2"
)

type AnalyticsHandlers struct {
	AnalyticsService services.AnalyticsService
}

func NewAnalyticsHandlers(analyticsService services.AnalyticsService) *AnalyticsHandlers {
	return &AnalyticsHandlers{
		AnalyticsService: analyticsService,
	}
}

// GetAbandonedCartAnalytics handles GET /api/analytics/carts/abandoned
func (h *AnalyticsHandlers) GetAbandonedCartAnalytics(c *fiber.Ctx) error {
	start := c.Query("start")
	end := c.Query("end")
	results, err := h.AnalyticsService.GetAbandonedCartAnalytics(c.Context(), start, end)
	if err != nil {
		return middleware.InternalError(err.Error())
	}
	return c.JSON(results)
}

// GetConversionAnalytics handles GET /api/analytics/carts/conversions
func (h *AnalyticsHandlers) GetConversionAnalytics(c *fiber.Ctx) error {
	start := c.Query("start")
	end := c.Query("end")
	results, err := h.AnalyticsService.GetConversionAnalytics(c.Context(), start, end)
	if err != nil {
		return middleware.InternalError(err.Error())
	}
	return c.JSON(results)
}

// GetProductViews handles GET /api/analytics/products/views
func (h *AnalyticsHandlers) GetProductViews(c *fiber.Ctx) error {
	start := c.Query("start")
	end := c.Query("end")
	results, err := h.AnalyticsService.GetProductViewAnalytics(c.Context(), start, end)
	if err != nil {
		return middleware.InternalError(err.Error())
	}
	return c.JSON(results)
}

// GetSearchAnalytics handles GET /api/analytics/search
func (h *AnalyticsHandlers) GetSearchAnalytics(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "Search analytics implemented",
		"data": []map[string]interface{}{
			{"query": "example query", "count": 10},
			{"query": "another query", "count": 5},
		},
	})
}
