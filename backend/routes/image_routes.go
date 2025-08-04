package routes

import (
	"mercadomio-backend/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupImageRoutes configures all image-related routes
func SetupImageRoutes(app *fiber.App, imageHandlers *handlers.ImageHandlers, cloudinaryHandlers *handlers.CloudinaryHandlers, directusHandlers *handlers.DirectusHandlers) {
	// Cloudinary proxy route for products (hidden from frontend)
	app.Get("/api/images/products/:path", cloudinaryHandlers.CloudinaryProxy)

	// Directus proxy routes for assets
	app.Get("/api/directus/assets/:path", directusHandlers.DirectusProxy)
	app.Get("/api/directus/assets/:path/:filename", directusHandlers.DirectusProxy)

	// Health check for image server
	app.Get("/api/images/health", imageHandlers.ImageServerHealth)
}
