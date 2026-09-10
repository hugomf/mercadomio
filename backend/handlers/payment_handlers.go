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
			"processed": false,
			"event_type": eventType,
		})
	}

	return middleware.Success(c, fiber.Map{
		"processed": true,
		"event_type": eventType,
	})
}

// StripeWebhook handles Stripe webhooks
// POST /api/payments/stripe-webhook
func (h *PaymentHandlers) StripeWebhook(c *fiber.Ctx) error {
	payload := c.Body()
	signature := c.Get("Stripe-Signature")

	eventType, err := h.paymentService.HandleStripeWebhook(c.Context(), payload, signature)
	if err != nil {
		log.Printf("[stripe-webhook] verification failed: %v", err)
		return middleware.BadRequestResponse(c, "invalid webhook signature")
	}

	return middleware.Success(c, fiber.Map{
		"processed": true,
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

// Confirmation renders a minimal confirmation page after redirect from payment provider.
// GET /payments/confirmation
func (h *PaymentHandlers) Confirmation(c *fiber.Ctx) error {
	orderID := c.Query("order_id", "")
	if orderID == "" {
		return c.Status(fiber.StatusBadRequest).SendString("missing order_id")
	}
	c.Set("Content-Type", "text/html; charset=utf-8")
	return c.Status(fiber.StatusOK).SendString(confirmationHTML(orderID, true))
}

// Cancelled renders a minimal cancellation page after redirect from payment provider.
// GET /payments/cancelled
func (h *PaymentHandlers) Cancelled(c *fiber.Ctx) error {
	orderID := c.Query("order_id", "")
	if orderID == "" {
		return c.Status(fiber.StatusBadRequest).SendString("missing order_id")
	}
	c.Set("Content-Type", "text/html; charset=utf-8")
	return c.Status(fiber.StatusOK).SendString(confirmationHTML(orderID, false))
}

func confirmationHTML(orderID string, success bool) string {
	title := "Pago confirmado"
	message := "Tu pago fue procesado."
	badge := "Éxito"
	badgeColor := "#166534"
	if !success {
		title = "Pago cancelado"
		message = "Tu pago no fue completado; puedes reintentar."
		badge = "Cancelado"
		badgeColor = "#991b1b"
	}
	return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>` + title + `</title>
<style>
  :root { font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, Helvetica, Arial, sans-serif; }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100dvh; display: grid; place-items: center; background: #f6f7f6; color: #1b1b1b; }
  .card { width: min(420px, 92vw); padding: 24px; border-radius: 16px; background: #ffffff; box-shadow: 0 10px 30px rgba(0,0,0,0.08); }
  .badge { display: inline-block; padding: 6px 10px; border-radius: 999px; background: #e5e7eb; color: ` + badgeColor + `; font-weight: 600; font-size: 12px; letter-spacing: .2px; }
  h1 { margin: 14px 0 8px; font-size: 22px; }
  p { margin: 0 0 18px; color: #4b5563; }
  .muted { font-size: 12px; color: #6b7280; }
  a.button { display: inline-block; padding: 12px 14px; border-radius: 12px; background: #166534; color: white; text-decoration: none; font-weight: 600; }
</style>
</head>
<body>
  <main class="card">
    <span class="badge">` + badge + `</span>
    <h1>` + title + `</h1>
    <p>` + message + `</p>
    <div class="muted">Pedido: ` + orderID + `</div>
    <br>
    <a class="button" href="/">Volver a la tienda</a>
  </main>
</body>
</html>`
}
