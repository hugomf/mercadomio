package routes

import (
	"mercadomio-backend/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupImageRoutes configures all image-related routes
func SetupImageRoutes(app *fiber.App, imageHandlers *handlers.ImageHandlers, imgVaultHandlers *handlers.ImgVaultHandlers, directusHandlers *handlers.DirectusHandlers) {
	// imgvault proxy routes for product images (hidden from frontend)
	app.Get("/api/imgvault/images/:id/file", imgVaultHandlers.ImgVaultFileProxy)
	app.Get("/api/imgvault/images/:id/variant/:variant", imgVaultHandlers.ImgVaultVariantProxy)
	app.Post("/api/imgvault/upload", imgVaultHandlers.ImgVaultUploadProxy)

	// Directus proxy routes for assets
	app.Get("/api/directus/assets/:path", directusHandlers.DirectusProxy)
	app.Get("/api/directus/assets/:path/:filename", directusHandlers.DirectusProxy)

	// Health check for image server
	app.Get("/api/images/health", imageHandlers.ImageServerHealth)
}
