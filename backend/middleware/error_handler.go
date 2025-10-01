package middleware

import (
	"log"

	"github.com/gofiber/fiber/v2"
)

// APIError represents a structured API error
type APIError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

// ErrorHandler provides centralized error handling
func ErrorHandler() fiber.ErrorHandler {
	return func(c *fiber.Ctx, err error) error {
		// Default to 500 server error
		code := fiber.StatusInternalServerError
		message := "Internal Server Error"
		details := err.Error()

		// Check if it's a Fiber error
		if e, ok := err.(*fiber.Error); ok {
			code = e.Code
			message = e.Message
		}

		// Log the error
		log.Printf("Error %d: %s - %s", code, message, details)

		// Return structured error response
		return c.Status(code).JSON(APIError{
			Code:    code,
			Message: message,
			Details: details,
		})
	}
}

// ErrorResponse sends an error response with custom status code (backward compatibility)
func ErrorResponseLegacy(c *fiber.Ctx, status int, code, message, details string) error {
	return c.Status(status).JSON(APIError{
		Code:    status,
		Message: message,
		Details: details,
	})
}

// These functions are kept for backward compatibility with new signature

// Old function signatures for backward compatibility (return *fiber.Error)
// These will be handled by Fiber's error handler

// BadRequest creates a 400 error (old style - returns *fiber.Error)
func BadRequest(message string) *fiber.Error {
	return fiber.NewError(fiber.StatusBadRequest, message)
}

// NotFound creates a 404 error (old style - returns *fiber.Error)
func NotFound(message string) *fiber.Error {
	return fiber.NewError(fiber.StatusNotFound, message)
}

// InternalError creates a 500 error (old style - returns *fiber.Error)
func InternalError(message string) *fiber.Error {
	return fiber.NewError(fiber.StatusInternalServerError, message)
}
