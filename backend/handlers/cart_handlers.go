package handlers

import (
	"mercadomio-backend/middleware"
	"mercadomio-backend/services"

	"github.com/gofiber/fiber/v2"
)

type CartHandlers struct {
	CartService services.CartService
}

func NewCartHandlers(cartService services.CartService) *CartHandlers {
	return &CartHandlers{
		CartService: cartService,
	}
}

// GetCart handles GET /api/cart/:cartId
func (h *CartHandlers) GetCart(c *fiber.Ctx) error {
	cartID := c.Params("cartId")
	cart, err := h.CartService.GetCart(c.Context(), cartID)
	if err != nil {
		return middleware.InternalError(err.Error())
	}
	return c.JSON(cart)
}

// AddToCart handles POST /api/cart/:cartId/items
func (h *CartHandlers) AddToCart(c *fiber.Ctx) error {
	cartID := c.Params("cartId")
	var item services.CartItem
	if err := c.BodyParser(&item); err != nil {
		return middleware.BadRequest("Invalid input")
	}
	if err := h.CartService.AddToCart(c.Context(), cartID, item); err != nil {
		return middleware.BadRequest(err.Error())
	}
	return c.SendStatus(201)
}

// UpdateCartItem handles PUT /api/cart/:cartId/items/:productId
func (h *CartHandlers) UpdateCartItem(c *fiber.Ctx) error {
	cartID := c.Params("cartId")
	productID := c.Params("productId")
	variantID := c.Query("variantId", "")
	var body struct {
		Quantity int `json:"quantity"`
	}
	if err := c.BodyParser(&body); err != nil {
		return middleware.BadRequest("Invalid input")
	}
	if err := h.CartService.UpdateCartItem(c.Context(), cartID, productID, variantID, body.Quantity); err != nil {
		return middleware.BadRequest(err.Error())
	}
	return c.SendStatus(204)
}

// RemoveFromCart handles DELETE /api/cart/:cartId/items/:productId
func (h *CartHandlers) RemoveFromCart(c *fiber.Ctx) error {
	cartID := c.Params("cartId")
	productID := c.Params("productId")
	variantID := c.Query("variantId", "")
	if err := h.CartService.RemoveFromCart(c.Context(), cartID, productID, variantID); err != nil {
		return middleware.BadRequest(err.Error())
	}
	return c.SendStatus(204)
}

// MergeCarts handles POST /api/cart/merge
func (h *CartHandlers) MergeCarts(c *fiber.Ctx) error {
	var body struct {
		GuestCartID string `json:"guestCartId"`
		UserCartID  string `json:"userCartId"`
	}
	if err := c.BodyParser(&body); err != nil {
		return middleware.BadRequest("Invalid input")
	}
	if err := h.CartService.MergeCarts(c.Context(), body.GuestCartID, body.UserCartID); err != nil {
		return middleware.BadRequest(err.Error())
	}
	return c.SendStatus(200)
}
