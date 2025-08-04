package handlers

import (
	"mercadomio-backend/middleware"

	"github.com/gofiber/fiber/v2"
)

func extractQueryParams(c *fiber.Ctx) (string, string, error) {
	start := c.Query("start")
	end := c.Query("end")

	if start == "" || end == "" {
		return "", "", middleware.BadRequest("start and end query parameters are required")
	}

	return start, end, nil
}
