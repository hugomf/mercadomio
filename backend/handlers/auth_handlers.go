package handlers

import (
	"mercadomio-backend/middleware"
	"mercadomio-backend/models"
	"mercadomio-backend/services"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson"
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

// resolveUser maps the OIDC identity attached by the middleware to the local
// user document, linking or creating it when needed.
func (h *AuthHandlers) resolveUser(c *fiber.Ctx) (*models.User, error) {
	sub := c.Locals("userID").(string)
	email, _ := c.Locals("userEmail").(string)
	name, _ := c.Locals("userName").(string)

	return h.authService.SyncUser(sub, email, name)
}

// GetProfile handles retrieving user profile
func (h *AuthHandlers) GetProfile(c *fiber.Ctx) error {
	user, err := h.resolveUser(c)
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
	user, err := h.resolveUser(c)
	if err != nil {
		return middleware.InternalError("Failed to retrieve user profile")
	}

	var updates map[string]interface{}
	if err := c.BodyParser(&updates); err != nil {
		return middleware.BadRequest("Invalid request body")
	}

	// Remove sensitive fields that shouldn't be updated via this endpoint
	delete(updates, "passwordHash")
	delete(updates, "email")       // Email changes should be handled separately
	delete(updates, "userbrewSub") // Identity is managed by userbrew

	err = h.authService.UpdateUser(user.ID.Hex(), updates)
	if err != nil {
		return middleware.InternalError("Failed to update profile")
	}

	// Get updated user
	user, err = h.authService.GetUserByID(user.ID.Hex())
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
	isAdmin, _ := c.Locals("isAdmin").(bool)

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Token is valid",
		"user": fiber.Map{
			"id":      userID,
			"email":   email,
			"isAdmin": isAdmin,
		},
	})
}

// GetUserAddresses handles retrieving user addresses
func (h *AuthHandlers) GetUserAddresses(c *fiber.Ctx) error {
	user, err := h.resolveUser(c)
	if err != nil {
		return middleware.InternalError("Failed to retrieve user addresses")
	}

	return c.JSON(fiber.Map{
		"success":   true,
		"addresses": user.Addresses,
	})
}

// CreateUserAddress handles adding a new address
func (h *AuthHandlers) CreateUserAddress(c *fiber.Ctx) error {
	user, err := h.resolveUser(c)
	if err != nil {
		return middleware.InternalError("Failed to retrieve user profile")
	}
	userID := user.ID.Hex()

	var address models.Address
	if err := c.BodyParser(&address); err != nil {
		return middleware.BadRequest("Invalid address data")
	}

	// Set defaults
	if address.IsDefault {
		// If this is default, unset other defaults
		for i := range user.Addresses {
			user.Addresses[i].IsDefault = false
		}
		err = h.authService.UpdateUser(userID, bson.M{"addresses": user.Addresses})
		if err != nil {
			return middleware.InternalError("Failed to update addresses")
		}
	}

	// Add the new address
	err = h.authService.AddUserAddress(userID, &address)
	if err != nil {
		return middleware.InternalError("Failed to add address")
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "Address added successfully",
		"address": address,
	})
}

// GetUserPaymentMethods handles retrieving user payment methods
func (h *AuthHandlers) GetUserPaymentMethods(c *fiber.Ctx) error {
	user, err := h.resolveUser(c)
	if err != nil {
		return middleware.InternalError("Failed to retrieve payment methods")
	}

	return c.JSON(fiber.Map{
		"success":        true,
		"paymentMethods": user.PaymentMethods,
	})
}

// CreateUserPaymentMethod handles adding a new payment method
func (h *AuthHandlers) CreateUserPaymentMethod(c *fiber.Ctx) error {
	user, err := h.resolveUser(c)
	if err != nil {
		return middleware.InternalError("Failed to retrieve user profile")
	}
	userID := user.ID.Hex()

	var paymentMethod models.PaymentMethod
	if err := c.BodyParser(&paymentMethod); err != nil {
		return middleware.BadRequest("Invalid payment method data")
	}

	// Set creation time and defaults
	paymentMethod.CreatedAt = time.Now()

	if paymentMethod.IsDefault {
		// If this is default, unset other defaults
		for i := range user.PaymentMethods {
			user.PaymentMethods[i].IsDefault = false
		}
		err = h.authService.UpdateUser(userID, bson.M{"paymentMethods": user.PaymentMethods})
		if err != nil {
			return middleware.InternalError("Failed to update payment methods")
		}
	}

	// Add the new payment method
	err = h.authService.AddUserPaymentMethod(userID, &paymentMethod)
	if err != nil {
		return middleware.InternalError("Failed to add payment method")
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success":       true,
		"message":       "Payment method added successfully",
		"paymentMethod": paymentMethod,
	})
}

// GetUserWishlist handles retrieving user wishlist
func (h *AuthHandlers) GetUserWishlist(c *fiber.Ctx) error {
	user, err := h.resolveUser(c)
	if err != nil {
		return middleware.InternalError("Failed to retrieve wishlist")
	}

	return c.JSON(fiber.Map{
		"success":  true,
		"wishlist": user.Wishlist,
	})
}

// AddToWishlist handles adding a product to user's wishlist
func (h *AuthHandlers) AddToWishlist(c *fiber.Ctx) error {
	user, err := h.resolveUser(c)
	if err != nil {
		return middleware.InternalError("Failed to retrieve user profile")
	}
	productID := c.Params("productId")

	err = h.authService.AddToUserWishlist(user.ID.Hex(), productID)
	if err != nil {
		return middleware.InternalError("Failed to add to wishlist")
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Product added to wishlist",
	})
}

// RemoveFromWishlist handles removing a product from user's wishlist
func (h *AuthHandlers) RemoveFromWishlist(c *fiber.Ctx) error {
	user, err := h.resolveUser(c)
	if err != nil {
		return middleware.InternalError("Failed to retrieve user profile")
	}
	productID := c.Params("productId")

	err = h.authService.RemoveFromUserWishlist(user.ID.Hex(), productID)
	if err != nil {
		return middleware.InternalError("Failed to remove from wishlist")
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Product removed from wishlist",
	})
}
