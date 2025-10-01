package middleware

import "github.com/gofiber/fiber/v2"

// Standard API Response structure
type APIResponse struct {
	Success bool              `json:"success"`
	Data    interface{}       `json:"data,omitempty"`
	Message string            `json:"message,omitempty"`
	Error   *APIResponseError `json:"error,omitempty"`
}

// API Error structure for failed responses
type APIResponseError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

// Success Response Helpers

// Success sends a successful response with data
func Success(c *fiber.Ctx, data interface{}, message ...string) error {
	response := APIResponse{
		Success: true,
		Data:    data,
	}
	if len(message) > 0 {
		response.Message = message[0]
	}
	return c.JSON(response)
}

// SuccessMessage sends a successful response with just a message
func SuccessMessage(c *fiber.Ctx, message string) error {
	response := APIResponse{
		Success: true,
		Message: message,
	}
	return c.JSON(response)
}

// Created sends a 201 created response with data
func Created(c *fiber.Ctx, data interface{}, message ...string) error {
	response := APIResponse{
		Success: true,
		Data:    data,
	}
	if len(message) > 0 {
		response.Message = message[0]
	}
	return c.Status(fiber.StatusCreated).JSON(response)
}

// NoContent sends a 204 no content response
func NoContent(c *fiber.Ctx) error {
	return c.Status(fiber.StatusNoContent).Send(nil)
}

// Error Response Helpers

// ErrorResponse sends an error response with custom status code
func ErrorResponse(c *fiber.Ctx, status int, code, message, details string) error {
	response := APIResponse{
		Success: false,
		Error: &APIResponseError{
			Code:    code,
			Message: message,
			Details: details,
		},
	}
	return c.Status(status).JSON(response)
}

// BadRequestResponse sends a 400 bad request error with consistent API format
func BadRequestResponse(c *fiber.Ctx, message string) error {
	return ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", message, "")
}

// BadRequestDetailsResponse sends a 400 bad request error with details (consistent format)
func BadRequestDetailsResponse(c *fiber.Ctx, message, details string) error {
	return ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", message, details)
}

// ValidationErrorResponse sends a 422 validation error (consistent format)
func ValidationErrorResponse(c *fiber.Ctx, message, details string) error {
	return ErrorResponse(c, fiber.StatusUnprocessableEntity, "VALIDATION_ERROR", message, details)
}

// Paginated Response Helper

// PaginatedData represents paginated response data
type PaginatedData struct {
	Items       interface{} `json:"items"`
	Total       int         `json:"total"`
	Page        int         `json:"page"`
	Limit       int         `json:"limit"`
	TotalPages  int         `json:"totalPages"`
	HasNextPage bool        `json:"hasNextPage"`
	HasPrevPage bool        `json:"hasPrevPage"`
}

// SuccessPaginated sends a successful paginated response
func SuccessPaginated(c *fiber.Ctx, items interface{}, total, page, limit int, message ...string) error {
	totalPages := (total + limit - 1) / limit // Ceiling division
	if totalPages == 0 {
		totalPages = 1
	}

	response := APIResponse{
		Success: true,
		Data: PaginatedData{
			Items:       items,
			Total:       total,
			Page:        page,
			Limit:       limit,
			TotalPages:  totalPages,
			HasNextPage: page < totalPages,
			HasPrevPage: page > 1,
		},
	}
	if len(message) > 0 {
		response.Message = message[0]
	}
	return c.JSON(response)
}
