package handlers

import (
	"mercadomio-backend/middleware"
	"mercadomio-backend/models"
<<<<<<< Updated upstream
	"mercadomio-backend/services"
	"strconv"
=======
>>>>>>> Stashed changes

	"github.com/gofiber/fiber/v2"
)

type OrderHandlers struct {
<<<<<<< Updated upstream
	orderService   *services.OrderService
	cartService    services.CartService
	productService services.ProductService
}

func NewOrderHandlers(orderService *services.OrderService, cartService services.CartService, productService services.ProductService) *OrderHandlers {
	return &OrderHandlers{
		orderService:   orderService,
		cartService:    cartService,
		productService: productService,
	}
}

// CreateOrder handles POST /api/orders
// Converts user's current cart to an order
func (h *OrderHandlers) CreateOrder(c *fiber.Ctx) error {
	// Get user ID from auth context (set by auth middleware)
	userID, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	// Get user's cart
	cartID := "user_" + userID // Assuming cart is keyed by userID
	cart, err := h.cartService.GetCart(c.Context(), cartID)
	if err != nil {
		return middleware.InternalError("failed to retrieve cart")
	}

	// Check if cart has items
	if len(cart.Items) == 0 {
		return middleware.BadRequestResponse(c, "cart is empty")
	}

	// Create order from cart
	order, err := h.orderService.CreateOrderFromCart(c.Context(), userID, cart.Items)
	if err != nil {
		return middleware.BadRequestResponse(c, "failed to create order: "+err.Error())
	}

	// Clear the cart after successful order creation
	// We'll need to modify cart service to clear cart by user ID
	// For now, just create order and return success

	return middleware.Created(c, order.ToResponse(), "order created successfully")
}

// GetOrder handles GET /api/orders/:id
func (h *OrderHandlers) GetOrder(c *fiber.Ctx) error {
	// Get user ID from auth context
	userID, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	orderID := c.Params("id")
	if orderID == "" {
		return middleware.BadRequestResponse(c, "order ID is required")
	}

	// Get the order
	order, err := h.orderService.GetOrderByID(c.Context(), orderID)
	if err != nil {
		return middleware.NotFoundResponse(c, "order not found")
	}

	// Verify the order belongs to the authenticated user
	if order.UserID.Hex() != userID {
		return middleware.Forbidden(c, "access denied")
	}

	return middleware.Success(c, order.ToResponse())
}

// GetUserOrders handles GET /api/orders
// Returns user's order history with pagination
func (h *OrderHandlers) GetUserOrders(c *fiber.Ctx) error {
	// Get user ID from auth context
	userID, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	// Parse pagination parameters
	page, err := strconv.Atoi(c.Query("page", "1"))
	if err != nil || page < 1 {
		page = 1
	}

	limit, err := strconv.Atoi(c.Query("limit", "20"))
	if err != nil || limit < 1 || limit > 100 {
		limit = 20
	}

	// Get user's orders
	orders, err := h.orderService.GetOrdersByUserID(c.Context(), userID, page, limit)
	if err != nil {
		return middleware.InternalError("failed to retrieve orders")
	}

	// Convert to response format
	var orderResponses []*models.OrderResponse
	for _, order := range orders {
		orderResponses = append(orderResponses, order.ToResponse())
	}

	totalCount := len(orderResponses) // In a real implementation, you'd get total count from service

	responseData := map[string]interface{}{
		"orders": orderResponses,
		"page":   page,
		"limit":  limit,
		"total":  totalCount, // This should come from service with separate count query
	}

	return middleware.Success(c, responseData)
}

// UpdateOrderStatus handles PUT /api/orders/:id/status (admin only)
// Note: In a real application, this should have admin role checking
func (h *OrderHandlers) UpdateOrderStatus(c *fiber.Ctx) error {
	// Get user ID from auth context - in production, check if admin
	_, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	orderID := c.Params("id")
	if orderID == "" {
		return middleware.BadRequestResponse(c, "order ID is required")
	}

	// Parse request body
	var body struct {
		Status string `json:"status"`
	}
	if err := c.BodyParser(&body); err != nil {
		return middleware.BadRequestResponse(c, "invalid request body")
	}

	// Validate status
	status := models.OrderStatus(body.Status)
	validStatuses := []models.OrderStatus{
		models.OrderStatusPending,
		models.OrderStatusPaid,
		models.OrderStatusShipped,
		models.OrderStatusCompleted,
		models.OrderStatusCancelled,
	}

	isValid := false
	for _, validStatus := range validStatuses {
		if status == validStatus {
			isValid = true
			break
		}
	}
	if !isValid {
		return middleware.BadRequestResponse(c, "invalid order status")
	}

	// Update status
	err := h.orderService.UpdateOrderStatus(c.Context(), orderID, status)
	if err != nil {
		return middleware.BadRequestResponse(c, "failed to update order status: "+err.Error())
	}

	return middleware.SuccessMessage(c, "order status updated successfully")
}

// AddPaymentInfo handles POST /api/orders/:id/payment
func (h *OrderHandlers) AddPaymentInfo(c *fiber.Ctx) error {
	// Get user ID from auth context
	userID, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	orderID := c.Params("id")
	if orderID == "" {
		return middleware.BadRequestResponse(c, "order ID is required")
	}

	// Parse request body
	var body struct {
		PaymentInfo map[string]interface{} `json:"paymentInfo"`
	}
	if err := c.BodyParser(&body); err != nil {
		return middleware.BadRequestResponse(c, "invalid request body")
	}

	// Verify order ownership
	order, err := h.orderService.GetOrderByID(c.Context(), orderID)
	if err != nil {
		return middleware.NotFoundResponse(c, "order not found")
	}

	if order.UserID.Hex() != userID {
		return middleware.Forbidden(c, "access denied")
	}

	// Update payment info and status
	if err := h.orderService.UpdateOrderPayment(c.Context(), orderID, body.PaymentInfo); err != nil {
		return middleware.BadRequestResponse(c, "failed to update payment info: "+err.Error())
	}

	return middleware.SuccessMessage(c, "payment information added successfully")
}

// GetOrderStats handles GET /api/orders/stats (admin only)
func (h *OrderHandlers) GetOrderStats(c *fiber.Ctx) error {
	// In production, check if user is admin
	_, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	stats, err := h.orderService.GetOrderStats(c.Context())
	if err != nil {
		return middleware.InternalError("failed to get order statistics")
	}

	return middleware.Success(c, stats)
=======
	// orderService will be implemented later
}

func NewOrderHandlers() *OrderHandlers {
	return &OrderHandlers{}
}

func (h *OrderHandlers) GetOrders(c *fiber.Ctx) error {
	// TODO: Implement actual order retrieval logic
	orders := []models.Order{}
	return c.JSON(orders)
}

func (h *OrderHandlers) CreateOrder(c *fiber.Ctx) error {
	var order models.Order
	if err := c.BodyParser(&order); err != nil {
		return middleware.BadRequest("Invalid request body")
	}

	// TODO: Implement actual order creation logic
	// For now, just return the order as created
	return c.Status(fiber.StatusCreated).JSON(order)
>>>>>>> Stashed changes
}
