package handlers

import (
	"fmt"
	"io"
	"net/http"
	"regexp"
	"time"

	"github.com/gofiber/fiber/v2"
)

type DirectusHandlers struct {
	directusURL string
}

func NewDirectusHandlers(directusURL string) *DirectusHandlers {
	return &DirectusHandlers{
		directusURL: directusURL,
	}
}

// DirectusProxy proxies requests to Directus assets with CORS support
func (h *DirectusHandlers) DirectusProxy(c *fiber.Ctx) error {
	assetPath := c.Params("path")
	filename := c.Params("filename", "")

	// Security: Validate asset path (UUID format)
	validUUID := regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`)
	if !validUUID.MatchString(assetPath) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid asset path",
		})
	}

	// Security: Validate filename if provided
	if filename != "" {
		validFilename := regexp.MustCompile(`^[a-zA-Z0-9._-]+\.(jpg|jpeg|png|gif|webp)$`)
		if !validFilename.MatchString(filename) {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "invalid filename",
			})
		}
	}

	// Build Directus asset URL
	var directusURL string
	if filename != "" {
		directusURL = fmt.Sprintf("%s/assets/%s/%s", h.directusURL, assetPath, filename)
	} else {
		directusURL = fmt.Sprintf("%s/assets/%s", h.directusURL, assetPath)
	}

	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	// Create request to Directus
	req, err := http.NewRequest("GET", directusURL, nil)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to create request",
		})
	}

	// Add headers
	req.Header.Set("User-Agent", "MercadoMio-Backend/1.0")

	// Make request to Directus
	resp, err := client.Do(req)
	if err != nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"error": "directus service unavailable",
		})
	}
	defer resp.Body.Close()

	// Check if asset exists
	if resp.StatusCode == http.StatusNotFound {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "asset not found",
		})
	}

	if resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(fiber.Map{
			"error": fmt.Sprintf("directus error: %d", resp.StatusCode),
		})
	}

	// Set response headers
	c.Set("Content-Type", resp.Header.Get("Content-Type"))
	c.Set("Content-Length", resp.Header.Get("Content-Length"))
	c.Set("Cache-Control", "public, max-age=3600") // 1 hour cache
	c.Set("Access-Control-Allow-Origin", "*")
	c.Set("Access-Control-Allow-Methods", "GET")

	// Set status
	c.Status(resp.StatusCode)

	// Stream the response
	_, err = io.Copy(c.Response().BodyWriter(), resp.Body)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "error streaming asset",
		})
	}

	return nil
}
