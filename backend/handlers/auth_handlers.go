package handlers

import (
	"mercadomio-backend/middleware"
	"mercadomio-backend/models"
	"mercadomio-backend/services"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

var validate = validator.New()

// AuthHandlers handles authentication-related HTTP requests
type AuthHandlers struct {
	authService *services.AuthService
}

// NewAuthHandlers creates new auth handlers
func NewAuthHandlers(authService *services.AuthService) *AuthHandlers {
	return &AuthHandlers{
		authService: authService,
	}
}

// AuthService returns the auth service
func (h *AuthHandlers) AuthService() *services.AuthService {
	return h.authService
}

// Register handles user registration
func (h *AuthHandlers) Register(c *fiber.Ctx) error {
	var req models.UserRegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return middleware.BadRequest("Invalid request body")
	}

	// Validate request
	if err := validate.Struct(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Validation failed",
			"errors":  err.Error(),
		})
	}

	user, err := h.authService.Register(&req)
	if err != nil {
		// Check for duplicate email
		if err.Error() == "user with this email already exists" {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"success": false,
				"message": err.Error(),
			})
		}

		return middleware.InternalError("Internal server error")
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "User registered successfully",
		"user":    user.ToResponse(),
	})
}

// Login handles user authentication
func (h *AuthHandlers) Login(c *fiber.Ctx) error {
	var req models.UserLoginRequest
	if err := c.BodyParser(&req); err != nil {
		return middleware.BadRequest("Invalid request body")
	}

	// Validate request
	if err := validate.Struct(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Validation failed",
			"errors":  err.Error(),
		})
	}

	authResponse, err := h.authService.Login(&req)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"message": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Login successful",
		"data":    authResponse,
	})
}

// GetProfile handles retrieving user profile
func (h *AuthHandlers) GetProfile(c *fiber.Ctx) error {
	userID := c.Locals("userID").(string)

	user, err := h.authService.GetUserByID(userID)
	if err != nil {
		return middleware.InternalError("Failed to retrieve user profile")
	}

	return c.JSON(fiber.Map{
		"success": true,
		"user":    user.ToResponse(),
	})
}

// UpdateProfile handles updating user profile
func (h *AuthHandlers) UpdateProfile(c *fiber.Ctx) error {
	userID := c.Locals("userID").(string)

	var updates map[string]interface{}
	if err := c.BodyParser(&updates); err != nil {
		return middleware.BadRequest("Invalid request body")
	}

	// Remove sensitive fields that shouldn't be updated via this endpoint
	delete(updates, "passwordHash")
	delete(updates, "email") // Email changes should be handled separately

	err := h.authService.UpdateUser(userID, updates)
	if err != nil {
		return middleware.InternalError("Failed to update profile")
	}

	// Get updated user
	user, err := h.authService.GetUserByID(userID)
	if err != nil {
		return middleware.InternalError("Failed to retrieve updated profile")
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Profile updated successfully",
		"user":    user.ToResponse(),
	})
}

// VerifyToken handles token verification
func (h *AuthHandlers) VerifyToken(c *fiber.Ctx) error {
	// If we reach here, the token has already been validated by the AuthMiddleware
	userID := c.Locals("userID").(string)
	email := c.Locals("userEmail").(string)
	userType := c.Locals("userType")

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Token is valid",
		"user": fiber.Map{
			"id":    userID,
			"email": email,
			"type":  userType,
		},
	})
}
