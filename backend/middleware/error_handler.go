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

// BadRequest creates a 400 error
func BadRequest(message string) *fiber.Error {
	return fiber.NewError(fiber.StatusBadRequest, message)
}

// NotFound creates a 404 error
func NotFound(message string) *fiber.Error {
	return fiber.NewError(fiber.StatusNotFound, message)
}

// InternalError creates a 500 error
func InternalError(message string) *fiber.Error {
	return fiber.NewError(fiber.StatusInternalServerError, message)
}
