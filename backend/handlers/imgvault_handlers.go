package handlers

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"time"

	"github.com/gofiber/fiber/v2"
)

// ImgVaultHandlers proxies image requests to the imgvault service so the
// storefront never talks to imgvault directly (single trusted ingress).
// The backend authenticates to imgvault with its own API key and returns
// only validated routes: fetching a stored image file and uploading one.
type ImgVaultHandlers struct {
	imgVaultURL string
	apiKey      string
}

func NewImgVaultHandlers(imgVaultURL, apiKey string) *ImgVaultHandlers {
	return &ImgVaultHandlers{
		imgVaultURL: imgVaultURL,
		apiKey:      apiKey,
	}
}

// ImgVaultFileProxy proxies GET {imgvault}/api/v1/images/:id/file.
func (h *ImgVaultHandlers) ImgVaultFileProxy(c *fiber.Ctx) error {
	id := c.Params("id")
	if !isUUID(id) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid image id",
		})
	}

	target := fmt.Sprintf("%s/api/v1/images/%s/file", h.imgVaultURL, id)
	resp, err := h.doRequest(c, http.MethodGet, target, nil)
	if err != nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"error": "image service unavailable",
		})
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "image not found",
		})
	}
	if resp.StatusCode >= 400 {
		return c.Status(resp.StatusCode).JSON(fiber.Map{
			"error": fmt.Sprintf("image service error: %d", resp.StatusCode),
		})
	}

	c.Set("Content-Type", resp.Header.Get("Content-Type"))
	c.Set("Cache-Control", "public, max-age=3600")
	c.Status(resp.StatusCode)
	_, err = io.Copy(c.Response().BodyWriter(), resp.Body)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "error streaming image",
		})
	}
	return nil
}

// ImgVaultUploadProxy proxies POST {imgvault}/api/v1/upload, forwarding the
// multipart form body (file) as-is.
func (h *ImgVaultHandlers) ImgVaultUploadProxy(c *fiber.Ctx) error {
	target := fmt.Sprintf("%s/api/v1/upload", h.imgVaultURL)
	body := c.Request().Body()
	resp, err := h.doRequest(c, http.MethodPost, target, body)
	if err != nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"error": "image upload service unavailable",
		})
	}
	defer resp.Body.Close()

	c.Set("Content-Type", resp.Header.Get("Content-Type"))
	c.Status(resp.StatusCode)
	_, err = io.Copy(c.Response().BodyWriter(), resp.Body)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "error streaming upload response",
		})
	}
	return nil
}

// doRequest builds and sends a proxied request to imgvault, copying the
// caller's content-type (so multipart uploads keep their boundary) and
// attaching the backend's imgvault API key.
func (h *ImgVaultHandlers) doRequest(c *fiber.Ctx, method, target string, body []byte) (*http.Response, error) {
	client := &http.Client{Timeout: 30 * time.Second}

	req, err := http.NewRequest(method, target, nil)
	if err != nil {
		return nil, err
	}

	if body != nil {
		req.Body = io.NopCloser(bytes.NewReader(body))
	}

	// Forward the caller's content type (preserves multipart boundary on upload)
	if ct := c.Get("Content-Type"); ct != "" {
		req.Header.Set("Content-Type", ct)
	}
	req.Header.Set("User-Agent", "MercadoMio-Backend/1.0")
	if h.apiKey != "" {
		req.Header.Set("Authorization", "Bearer "+h.apiKey)
	}

	return client.Do(req)
}

func isUUID(s string) bool {
	return regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`).MatchString(s)
}
