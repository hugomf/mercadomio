package routes

import (
	"mercadomio-backend/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupPaymentRoutes configures the payment-related routes
func SetupPaymentRoutes(app *fiber.App, handlers *PaymentHandlers) {
	// Payment routes group with authentication (except stripe-config endpoint)
	v1 := app.Group("/api")

	// Public endpoint - no auth required for Stripe config
	v1.Get("/payments/stripe-config", handlers.GetStripeConfig)

	// Authenticated payment endpoints
	// Note: Auth middleware is applied per-route through the AuthWindowHandler pattern
	// The specific auth logic is handled in the handlers themselves

	payments := v1.Group("/payments")

	// Payment intent management
	payments.Post("/create-payment-intent", handlers.CreatePaymentIntent)
	payments.Post("/confirm", handlers.ConfirmPayment)
	payments.Post("/cancel", handlers.CancelPayment)
	payments.Get("/intent/:id", handlers.GetPaymentIntentDetails)

	// Demo/Simulation endpoint
	payments.Post("/simulate-success", handlers.SimulatePayment)

	// Webhook endpoint (can be unauthenticated but would need different auth)
	payments.Post("/webhook", handlers.WebhookHandler)
}

// PaymentHandlers holds all payment-related handlers
type PaymentHandlers struct {
	handlers *handlers.PaymentHandlers
}

// NewPaymentHandlers creates payment route handlers
func NewPaymentHandlers(handlers *handlers.PaymentHandlers) *PaymentHandlers {
	return &PaymentHandlers{
		handlers: handlers,
	}
}

// CreatePaymentIntent handles POST /api/payments/create-payment-intent
func (h *PaymentHandlers) CreatePaymentIntent(c *fiber.Ctx) error {
	return h.handlers.CreatePaymentIntent(c)
}

// ConfirmPayment handles POST /api/payments/confirm
func (h *PaymentHandlers) ConfirmPayment(c *fiber.Ctx) error {
	return h.handlers.ConfirmPayment(c)
}

// CancelPayment handles POST /api/payments/cancel
func (h *PaymentHandlers) CancelPayment(c *fiber.Ctx) error {
	return h.handlers.CancelPayment(c)
}

// GetPaymentIntentDetails handles GET /api/payments/intent/:id
func (h *PaymentHandlers) GetPaymentIntentDetails(c *fiber.Ctx) error {
	return h.handlers.GetPaymentIntentDetails(c)
}

// GetStripeConfig handles GET /api/payments/stripe-config
func (h *PaymentHandlers) GetStripeConfig(c *fiber.Ctx) error {
	return h.handlers.GetStripeConfig(c)
}

// SimulatePayment handles POST /api/payments/simulate-success
func (h *PaymentHandlers) SimulatePayment(c *fiber.Ctx) error {
	return h.handlers.SimulatePayment(c)
}

// WebhookHandler handles POST /api/payments/webhook
func (h *PaymentHandlers) WebhookHandler(c *fiber.Ctx) error {
	return h.handlers.WebhookHandler(c)
}
