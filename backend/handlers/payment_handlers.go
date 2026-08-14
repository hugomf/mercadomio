package handlers

import (
	"log"
	"mercadomio-backend/middleware"
	"mercadomio-backend/services"

	"github.com/gofiber/fiber/v2"
)

// PaymentHandlers handles payment-related HTTP requests
type PaymentHandlers struct {
	paymentService *services.PaymentService
}

// NewPaymentHandlers creates new payment handlers
func NewPaymentHandlers(paymentService *services.PaymentService) *PaymentHandlers {
	return &PaymentHandlers{
		paymentService: paymentService,
	}
}

// CreatePaymentIntent creates a Stripe PaymentIntent for an order
// POST /api/payments/create-payment-intent
func (h *PaymentHandlers) CreatePaymentIntent(c *fiber.Ctx) error {
	// Get authenticated user
	userID, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	log.Printf("User %s creating payment intent", userID)

	// Parse request body
	var req struct {
		OrderID string `json:"orderId"`
	}
	if err := c.BodyParser(&req); err != nil {
		return middleware.BadRequestResponse(c, "invalid request body")
	}

	if req.OrderID == "" {
		return middleware.BadRequestResponse(c, "order ID is required")
	}

	// Create payment intent
	paymentIntent, err := h.paymentService.CreatePaymentIntent(c.Context(), req.OrderID, userID)
	if err != nil {
		return middleware.BadRequestResponse(c, "failed to create payment intent: "+err.Error())
	}

	// Return payment intent details
	responseData := fiber.Map{
		"clientSecret":    paymentIntent.ClientSecret,
		"paymentIntentId": paymentIntent.ID,
		"amount":          paymentIntent.Amount,
		"currency":        paymentIntent.Currency,
	}

	return middleware.Success(c, responseData)
}

// ConfirmPayment confirms a payment
// POST /api/payments/confirm
func (h *PaymentHandlers) ConfirmPayment(c *fiber.Ctx) error {
	// Get authenticated user
	userID, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	log.Printf("User %s confirming payment", userID)

	// Parse request body
	var req struct {
		PaymentIntentID string `json:"paymentIntentId"`
		PaymentMethodID string `json:"paymentMethodId"`
	}
	if err := c.BodyParser(&req); err != nil {
		return middleware.BadRequestResponse(c, "invalid request body")
	}

	if req.PaymentIntentID == "" || req.PaymentMethodID == "" {
		return middleware.BadRequestResponse(c, "payment intent ID and payment method ID are required")
	}

	// Confirm payment
	err := h.paymentService.ConfirmPaymentIntent(c.Context(), req.PaymentIntentID, req.PaymentMethodID)
	if err != nil {
		return middleware.BadRequestResponse(c, "payment confirmation failed: "+err.Error())
	}

	return middleware.SuccessMessage(c, "payment confirmed successfully")
}

// CancelPayment cancels a payment intent
// POST /api/payments/cancel
func (h *PaymentHandlers) CancelPayment(c *fiber.Ctx) error {
	// Get authenticated user
	userID, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	log.Printf("User %s canceling payment", userID)

	// Parse request body
	var req struct {
		PaymentIntentID string `json:"paymentIntentId"`
	}
	if err := c.BodyParser(&req); err != nil {
		return middleware.BadRequestResponse(c, "invalid request body")
	}

	if req.PaymentIntentID == "" {
		return middleware.BadRequestResponse(c, "payment intent ID is required")
	}

	// Cancel payment intent
	err := h.paymentService.CancelPaymentIntent(c.Context(), req.PaymentIntentID)
	if err != nil {
		return middleware.BadRequestResponse(c, "failed to cancel payment: "+err.Error())
	}

	return middleware.SuccessMessage(c, "payment cancelled successfully")
}

// GetPaymentIntentDetails gets details of a payment intent
// GET /api/payments/intent/:id
func (h *PaymentHandlers) GetPaymentIntentDetails(c *fiber.Ctx) error {
	// Get authenticated user
	userID, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	log.Printf("User %s retrieving payment intent details", userID)

	paymentIntentID := c.Params("id")
	if paymentIntentID == "" {
		return middleware.BadRequestResponse(c, "payment intent ID is required")
	}

	// Get payment intent details
	paymentIntent, err := h.paymentService.GetPaymentIntent(paymentIntentID)
	if err != nil {
		return middleware.NotFoundResponse(c, "payment intent not found")
	}

	// Return payment intent details (sanitized for client)
	responseData := fiber.Map{
		"id":           paymentIntent.ID,
		"amount":       paymentIntent.Amount,
		"currency":     paymentIntent.Currency,
		"status":       paymentIntent.Status,
		"clientSecret": paymentIntent.ClientSecret,
		"description":  paymentIntent.Description,
	}

	return middleware.Success(c, responseData)
}

// GetStripePublicKey returns the Stripe public key for client-side use
// GET /api/payments/stripe-config
func (h *PaymentHandlers) GetStripeConfig(c *fiber.Ctx) error {
	// This endpoint doesn't require authentication for public key access
	publicKey := h.paymentService.GetPublicKey()
	responseData := fiber.Map{
		"stripePublicKey": publicKey,
	}

	return middleware.Success(c, responseData)
}

// SimulatePayment simulates a successful payment for demo purposes
// POST /api/payments/simulate-success
func (h *PaymentHandlers) SimulatePayment(c *fiber.Ctx) error {
	// Get authenticated user
	userID, ok := c.Locals("userID").(string)
	if !ok {
		return middleware.Unauthorized(c, "authentication required")
	}

	log.Printf("User %s simulating payment success", userID)

	// Parse request body
	var req struct {
		OrderID string `json:"orderId"`
	}
	if err := c.BodyParser(&req); err != nil {
		return middleware.BadRequestResponse(c, "invalid request body")
	}

	if req.OrderID == "" {
		return middleware.BadRequestResponse(c, "order ID is required")
	}

	// Simulate payment success
	err := h.paymentService.SimulatePaymentSuccess(c.Context(), req.OrderID)
	if err != nil {
		return middleware.BadRequestResponse(c, "payment simulation failed: "+err.Error())
	}

	return middleware.SuccessMessage(c, "payment simulated successfully")
}

// WebhookHandler handles Conekta webhooks
// POST /api/payments/webhook
func (h *PaymentHandlers) WebhookHandler(c *fiber.Ctx) error {
	payload := c.Body()
	signature := c.Get("DIGEST")

	// Validate webhook signature (RSA-SHA256 over raw body)
	if err := h.paymentService.ValidateConektaWebhookSignature(payload, signature); err != nil {
		log.Printf("Webhook signature validation failed: %v", err)
		return middleware.BadRequestResponse(c, "invalid webhook signature")
	}

	eventType, err := h.paymentService.HandleConektaWebhook(c.Context(), payload)
	if err != nil {
		log.Printf("Webhook processing error (%s): %v", eventType, err)
		return middleware.Success(c, fiber.Map{
			"processed":  false,
			"event_type": eventType,
		})
	}

	return middleware.Success(c, fiber.Map{
		"processed":  true,
		"event_type": eventType,
	})
}

// CreateCheckout creates a Conekta hosted checkout session for an order
// POST /api/payments/checkout
func (h *PaymentHandlers) CreateCheckout(c *fiber.Ctx) error {
	// Payments routes are not behind AuthMiddleware; resolve the user
	// leniently so demo/guest flows work. Ownership is enforced by the
	// service when a userID is present.
	userID, _ := c.Locals("userID").(string)

	log.Printf("User %s creating checkout", userID)

	var req struct {
		OrderID string `json:"orderId"`
	}
	if err := c.BodyParser(&req); err != nil {
		return middleware.BadRequestResponse(c, "invalid request body")
	}
	if req.OrderID == "" {
		return middleware.BadRequestResponse(c, "order ID is required")
	}

	session, err := h.paymentService.CreateCheckoutSession(c.Context(), req.OrderID, userID)
	if err != nil {
		return middleware.BadRequestResponse(c, "failed to create checkout: "+err.Error())
	}

	return middleware.Success(c, fiber.Map{
		"checkoutUrl":    session.CheckoutURL,
		"checkoutId":     session.CheckoutID,
		"conektaOrderId": session.ConektaOrderID,
		"demo":           !h.paymentService.IsConektaConfigured(),
	})
}
