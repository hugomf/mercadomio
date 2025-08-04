package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

// SetupCORS configures CORS middleware
func SetupCORS() fiber.Handler {
	return cors.New(cors.Config{
		AllowOrigins:     "*", // In production, specify exact origins
		AllowMethods:     "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders:     "Origin,Content-Type,Accept,Authorization",
		AllowCredentials: false,
	})
}
