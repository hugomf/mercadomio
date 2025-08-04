package handlers

import (
	"os"

	"github.com/gofiber/fiber/v2"
)

type ImageHandlers struct{}

func NewImageHandlers() *ImageHandlers {
	return &ImageHandlers{}
}

// ImageServerHealth provides health check for the image server
func (h *ImageHandlers) ImageServerHealth(c *fiber.Ctx) error {
	// Check if images directory exists
	imagesDir := "./frontend/web/assets/images"
	if _, err := os.Stat(imagesDir); os.IsNotExist(err) {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"status":  "error",
			"message": "Images directory not found",
		})
	}

	// Check if we can read the directory
	if _, err := os.ReadDir(imagesDir); err != nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"status":  "error",
			"message": "Cannot read images directory",
		})
	}

	return c.JSON(fiber.Map{
		"status":      "ok",
		"message":     "Image server is running",
		"images_path": imagesDir,
	})
}
