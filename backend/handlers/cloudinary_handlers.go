package handlers

import (
	"fmt"
	"io"
	"net/http"
	"regexp"
	"time"

	"github.com/gofiber/fiber/v2"
)

type CloudinaryHandlers struct {
	cloudName      string
	productsFolder string
}

func NewCloudinaryHandlers(cloudName, productsFolder string) *CloudinaryHandlers {
	return &CloudinaryHandlers{
		cloudName:      cloudName,
		productsFolder: productsFolder,
	}
}

// CloudinaryProxy proxies requests to Cloudinary with security validation
func (h *CloudinaryHandlers) CloudinaryProxy(c *fiber.Ctx) error {
	imagePath := c.Params("path")
	transformation := c.Query("t", "f_auto,q_auto") // Default optimization

	// 🐛 DEBUG: Log initial request parameters
	fmt.Printf("🔍 [CLOUDINARY DEBUG] Initial request:\n")
	fmt.Printf("   - Original imagePath: '%s'\n", imagePath)
	fmt.Printf("   - Transformation: '%s'\n", transformation)
	fmt.Printf("   - CloudName: '%s'\n", h.cloudName)
	fmt.Printf("   - ProductsFolder: '%s'\n", h.productsFolder)

	// Clean the image path - remove any URL prefixes that might be passed
	imagePath = regexp.MustCompile(`^https?://.+/images/products/`).ReplaceAllString(imagePath, "")
	imagePath = regexp.MustCompile(`^http://.+/api/images/products/`).ReplaceAllString(imagePath, "")
	imagePath = regexp.MustCompile(`^https://.+/api/images/products/`).ReplaceAllString(imagePath, "")

	// Remove any leading slashes
	imagePath = regexp.MustCompile(`^/+`).ReplaceAllString(imagePath, "")

	// 🐛 DEBUG: Log cleaned path
	fmt.Printf("   - Cleaned imagePath: '%s'\n", imagePath)

	// Security: Validate image path (alphanumeric, hyphens, underscores, dots only)
	validPath := regexp.MustCompile(`^[a-zA-Z0-9._-]+$`)
	if !validPath.MatchString(imagePath) {
		fmt.Printf("❌ [CLOUDINARY DEBUG] Invalid path validation failed: '%s'\n", imagePath)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":    "invalid image path",
			"received": imagePath,
			"expected": "alphanumeric characters, hyphens, underscores, and dots only",
		})
	}
	fmt.Printf("✅ [CLOUDINARY DEBUG] Path validation passed\n")

	// Security: Validate transformation (only allowed characters)
	validTransform := regexp.MustCompile(`^[a-zA-Z0-9,._-]+$`)
	if !validTransform.MatchString(transformation) {
		transformation = "f_auto,q_auto" // Fallback to safe default
	}

	// Build secure Cloudinary URL - images are stored directly without products folder
	cloudinaryURL := fmt.Sprintf(
		"https://res.cloudinary.com/%s/image/upload/%s/%s",
		h.cloudName, transformation, imagePath,
	)

	// 🐛 DEBUG: Log the final Cloudinary URL being requested
	fmt.Printf("🔗 [CLOUDINARY DEBUG] Final URL: %s\n", cloudinaryURL)

	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	// Create request to Cloudinary
	req, err := http.NewRequest("GET", cloudinaryURL, nil)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to create request",
		})
	}

	// Make request to Cloudinary
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("❌ [CLOUDINARY DEBUG] Request failed: %v\n", err)
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"error": "image service unavailable",
		})
	}
	defer resp.Body.Close()

	// 🐛 DEBUG: Log response status and headers
	fmt.Printf("📡 [CLOUDINARY DEBUG] Response status: %d %s\n", resp.StatusCode, resp.Status)
	fmt.Printf("   - Content-Type: %s\n", resp.Header.Get("Content-Type"))
	fmt.Printf("   - Content-Length: %s\n", resp.Header.Get("Content-Length"))

	// Check if image exists
	if resp.StatusCode == http.StatusNotFound {
		fmt.Printf("❌ [CLOUDINARY DEBUG] Image not found (404) for URL: %s\n", cloudinaryURL)
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "image not found",
			"url":   cloudinaryURL,
		})
	}

	// Check for other error status codes
	if resp.StatusCode >= 400 {
		fmt.Printf("❌ [CLOUDINARY DEBUG] Cloudinary error %d for URL: %s\n", resp.StatusCode, cloudinaryURL)
		return c.Status(resp.StatusCode).JSON(fiber.Map{
			"error": fmt.Sprintf("cloudinary error: %d", resp.StatusCode),
			"url":   cloudinaryURL,
		})
	}

	// IMPORTANTE: Manejar Content-Encoding y Transfer-Encoding
	// contentEncoding := resp.Header.Get("Content-Encoding")
	// transferEncoding := resp.Header.Get("Transfer-Encoding")
	// fmt.Printf("Content-Encoding: %s, Transfer-Encoding: %s\n", contentEncoding, transferEncoding)

	// Copiar headers a la respuesta
	for key, values := range resp.Header {
		if key != "Connection" && key != "Server" {
			for _, value := range values {
				c.Set(key, value)
			}
		}
	}

	// Agregar CORS
	c.Set("Access-Control-Allow-Origin", "*")

	// Establecer status
	c.Status(resp.StatusCode)

	// SOLUCIÓN DEFINITIVA: Usar io.Copy para manejar correctamente el stream
	bytesWritten, err := io.Copy(c.Response().BodyWriter(), resp.Body)
	if err != nil {
		fmt.Printf("❌ [CLOUDINARY DEBUG] ERROR al copiar body: %v\n", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "error al transmitir imagen",
		})
	}

	// 🐛 DEBUG: Log successful response
	fmt.Printf("✅ [CLOUDINARY DEBUG] Successfully served image: %d bytes\n", bytesWritten)
	fmt.Printf("   - URL: %s\n", cloudinaryURL)

	return nil
}
