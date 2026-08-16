package services

import (
	"bytes"
	"context"
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"mercadomio-backend/models"

	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/paymentintent"
)

const conektaAPIBase = "https://api.conekta.io"

// PaymentService handles payment processing via Stripe and Conekta
type PaymentService struct {
	stripeSecretKey string
	stripePublicKey string
	baseURL         string
	orderService    *OrderService

	conektaSecretKey        string
	conektaPublicKey        string
	conektaWebhookPublicKey string
}

// CheckoutSession represents a Conekta hosted checkout session
type CheckoutSession struct {
	CheckoutURL    string `json:"checkoutUrl"`
	CheckoutID     string `json:"checkoutId"`
	ConektaOrderID string `json:"conektaOrderId"`
}

// NewPaymentService creates a new payment service
func NewPaymentService(orderService *OrderService) *PaymentService {
	// Initialize Stripe (legacy/demo path)
	stripeSecretKey := os.Getenv("STRIPE_SECRET_KEY")
	if stripeSecretKey == "" {
		stripeSecretKey = "sk_test_dummy_key_for_demo" // Demo fallback
	}

	stripePublicKey := os.Getenv("STRIPE_PUBLIC_KEY")
	if stripePublicKey == "" {
		stripePublicKey = "pk_test_dummy_key_for_demo"
	}

	stripe.Key = stripeSecretKey

	baseURL := os.Getenv("BASE_URL")
	if baseURL == "" {
		baseURL = "http://localhost:8080"
	}

	return &PaymentService{
		stripeSecretKey:         stripeSecretKey,
		stripePublicKey:         stripePublicKey,
		baseURL:                 baseURL,
		orderService:            orderService,
		conektaSecretKey:        os.Getenv("CONEKTA_SECRET_KEY"),
		conektaPublicKey:        os.Getenv("CONEKTA_PUBLIC_KEY"),
		conektaWebhookPublicKey: os.Getenv("CONEKTA_WEBHOOK_PUBLIC_KEY"),
	}
}

// CreatePaymentIntent creates a Stripe PaymentIntent for an order
func (s *PaymentService) CreatePaymentIntent(ctx context.Context, orderID string, userID string) (*stripe.PaymentIntent, error) {
	// Get the order details
	order, err := s.orderService.GetOrderByID(ctx, orderID)
	if err != nil {
		return nil, fmt.Errorf("failed to get order: %w", err)
	}

	// Verify order ownership
	if order.UserID.Hex() != userID {
		return nil, fmt.Errorf("unauthorized access to order")
	}

	// Check if order can be paid
	if order.Status != models.OrderStatusPending {
		return nil, fmt.Errorf("order is not in payable state")
	}

	// Calculate amount in cents (assuming order.Total is in dollars)
	amount := int64(order.Total * 100) // Convert to cents

	// Create payment intent parameters
	params := &stripe.PaymentIntentParams{
		Amount:   stripe.Int64(amount),
		Currency: stripe.String("usd"),
		Metadata: map[string]string{
			"order_id": orderID,
			"user_id":  userID,
		},
		Description: stripe.String(fmt.Sprintf("Order %s", orderID)),
		Shipping: &stripe.ShippingDetailsParams{
			Name: stripe.String(order.UserID.Hex()), // In real app, get user shipping info
		},
	}

	// Create the payment intent
	pi, err := paymentintent.New(params)
	if err != nil {
		log.Printf("Failed to create payment intent: %v", err)
		return nil, fmt.Errorf("failed to create payment intent")
	}

	log.Printf("Created payment intent: %s for order %s", pi.ID, orderID)
	return pi, nil
}

// ConfirmPaymentIntent confirms a payment and updates order status
func (s *PaymentService) ConfirmPaymentIntent(ctx context.Context, paymentIntentID string, paymentMethodID string) error {
	// Get payment intent to find order ID
	pi, err := paymentintent.Get(paymentIntentID, nil)
	if err != nil {
		return fmt.Errorf("failed to get payment intent: %w", err)
	}

	orderID, exists := pi.Metadata["order_id"]
	if !exists {
		return fmt.Errorf("payment intent missing order ID")
	}

	// Confirm the payment intent
	confirmParams := &stripe.PaymentIntentConfirmParams{
		PaymentMethod: stripe.String(paymentMethodID),
		ReturnURL:     stripe.String(fmt.Sprintf("%s/confirmed", s.baseURL)),
	}

	confirmedPI, err := paymentintent.Confirm(paymentIntentID, confirmParams)
	if err != nil {
		log.Printf("Payment failed: %v", err)
		// Update order status to cancelled
		s.orderService.UpdateOrderStatus(ctx, orderID, models.OrderStatusCancelled)
		return fmt.Errorf("payment confirmation failed")
	}

	// Check if payment succeeded
	if confirmedPI.Status == stripe.PaymentIntentStatusSucceeded {
		// Update order status and add payment info
		paymentInfo := map[string]interface{}{
			"stripe_payment_intent_id": confirmedPI.ID,
			"payment_method_id":        paymentMethodID,
			"amount":                   confirmedPI.AmountReceived / 100, // Convert back to dollars
			"currency":                 confirmedPI.Currency,
			"status":                   "completed",
			"processed_at":             time.Now().Format(time.RFC3339),
		}

		err = s.orderService.UpdateOrderPayment(ctx, orderID, paymentInfo)
		if err != nil {
			log.Printf("Failed to update order after payment: %v", err)
		}

		// Update order status to paid
		err = s.orderService.UpdateOrderStatus(ctx, orderID, models.OrderStatusPaid)
		if err != nil {
			log.Printf("Failed to update order status to paid: %v", err)
		}

		log.Printf("Order %s paid successfully", orderID)
		return nil
	} else if confirmedPI.Status == stripe.PaymentIntentStatusRequiresAction {
		// Additional authentication required
		return fmt.Errorf("additional authentication required")
	} else {
		// Payment failed
		log.Printf("Payment failed with status: %s", confirmedPI.Status)
		return fmt.Errorf("payment failed: %s", confirmedPI.Status)
	}
}

// CancelPaymentIntent cancels a payment intent
func (s *PaymentService) CancelPaymentIntent(ctx context.Context, paymentIntentID string) error {
	// Cancel the payment intent
	cancel := &stripe.PaymentIntentCancelParams{
		CancellationReason: stripe.String("requested_by_customer"),
	}

	_, err := paymentintent.Cancel(paymentIntentID, cancel)
	if err != nil {
		return fmt.Errorf("failed to cancel payment intent: %w", err)
	}

	return nil
}

// GetPaymentIntent retrieves payment intent details
func (s *PaymentService) GetPaymentIntent(paymentIntentID string) (*stripe.PaymentIntent, error) {
	pi, err := paymentintent.Get(paymentIntentID, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get payment intent: %w", err)
	}

	return pi, nil
}

// ValidateWebhookSignature validates Stripe webhook signatures
func (s *PaymentService) ValidateWebhookSignature(payload []byte, signature string) error {
	// Webhook signature validation
	endpointSecret := os.Getenv("STRIPE_WEBHOOK_SECRET")
	if endpointSecret == "" {
		return fmt.Errorf("webhook secret not configured")
	}

	// In a real implementation, you'd validate the signature here
	// For demo purposes, we'll just log it
	log.Printf("Webhook signature validation: %s", signature)
	return nil
}

// GetPublicKey returns the Stripe public key for client-side use
func (s *PaymentService) GetPublicKey() string {
	return s.stripePublicKey
}

// SimulatePaymentSuccess simulates payment success for demo purposes
func (s *PaymentService) SimulatePaymentSuccess(ctx context.Context, orderID string) error {
	// In a real app, this would integrate with payment provider
	paymentInfo := map[string]interface{}{
		"provider":      "STRIPE_SIMULATION",
		"transactionId": fmt.Sprintf("txn_%d", time.Now().Unix()),
		"amount":        0, // Would be populated from order
		"status":        "completed",
		"simulated":     true,
		"processedAt":   time.Now().Format(time.RFC3339),
	}

	err := s.orderService.UpdateOrderPayment(ctx, orderID, paymentInfo)
	if err != nil {
		return fmt.Errorf("failed to update payment info: %w", err)
	}

	err = s.orderService.UpdateOrderStatus(ctx, orderID, models.OrderStatusPaid)
	if err != nil {
		return fmt.Errorf("failed to update order status: %w", err)
	}

	log.Printf("Order %s payment simulated successfully", orderID)
	return nil
}

// IsConektaConfigured returns true when real Conekta keys are present
func (s *PaymentService) IsConektaConfigured() bool {
	return s.conektaSecretKey != ""
}

// CreateCheckoutSession creates a Conekta hosted checkout for an order.
// When no CONEKTA_SECRET_KEY is configured, a demo checkout URL is returned
// and the frontend falls back to the simulate-success flow.
func (s *PaymentService) CreateCheckoutSession(ctx context.Context, orderID string, userID string) (*CheckoutSession, error) {
	order, err := s.orderService.GetOrderByID(ctx, orderID)
	if err != nil {
		return nil, fmt.Errorf("failed to get order: %w", err)
	}

	if userID != "" && order.UserID.Hex() != userID {
		return nil, fmt.Errorf("unauthorized access to order")
	}

	if order.Status != models.OrderStatusPending {
		return nil, fmt.Errorf("order is not in payable state")
	}

	// Demo fallback: no Conekta key configured
	if s.conektaSecretKey == "" {
		log.Printf("Conekta not configured; using demo checkout for order %s", orderID)
		return &CheckoutSession{
			CheckoutURL:    s.baseURL + "/api/payments/demo?order_id=" + orderID,
			CheckoutID:     "demo-" + orderID,
			ConektaOrderID: "demo-" + orderID,
		}, nil
	}

	lineItems := make([]map[string]interface{}, 0, len(order.Items))
	for _, item := range order.Items {
		name := item.ProductName
		if name == "" {
			name = "Producto"
		}
		lineItems = append(lineItems, map[string]interface{}{
			"name":       name,
			"unit_price": int(item.Price * 100), // integer cents
			"quantity":   item.Quantity,
		})
	}

	successURL := s.baseURL + "/payments/confirmation?order_id=" + orderID
	failureURL := s.baseURL + "/payments/cancelled?order_id=" + orderID
	if envSuccess := os.Getenv("CONEKTA_SUCCESS_URL"); envSuccess != "" {
		successURL = envSuccess + "?order_id=" + orderID
	}
	if envFailure := os.Getenv("CONEKTA_FAILURE_URL"); envFailure != "" {
		failureURL = envFailure + "?order_id=" + orderID
	}

	body := map[string]interface{}{
		"currency": "MXN",
		"customer_info": map[string]interface{}{
			"name":  "Mercado Mio Customer",
			"email": "customer@mercadomio.mx",
		},
		"line_items": lineItems,
		"checkout": map[string]interface{}{
			"type":                    "HostedPayment",
			"name":                    "Mercado Mio Order " + orderID,
			"success_url":             successURL,
			"failure_url":             failureURL,
			"allowed_payment_methods": []string{"card", "cash", "bank_transfer"},
		},
		"metadata": map[string]interface{}{
			"internal_order_id": orderID,
		},
		"pre_authorize": false,
	}

	payload, err := json.Marshal(body)
	if err != nil {
		return nil, fmt.Errorf("failed to encode checkout request: %w", err)
	}

	resp, err := s.conektaRequest(ctx, http.MethodPost, "/orders", payload)
	if err != nil {
		return nil, fmt.Errorf("conekta request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read conekta response: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("conekta error %d: %s", resp.StatusCode, string(respBody))
	}

	var result struct {
		ID       string `json:"id"`
		Checkout struct {
			URL string `json:"url"`
			ID  string `json:"id"`
		} `json:"checkout"`
	}
	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, fmt.Errorf("failed to parse conekta response: %w", err)
	}
	if result.Checkout.URL == "" {
		return nil, fmt.Errorf("conekta did not return a checkout URL")
	}

	// Store the Conekta order reference so webhooks can map back to the order
	ref := map[string]interface{}{
		"provider":         "conekta",
		"conekta_order_id": result.ID,
		"checkout_id":      result.Checkout.ID,
		"status":           "pending",
	}
	if err := s.orderService.AttachPaymentInfo(ctx, orderID, ref); err != nil {
		return nil, fmt.Errorf("failed to store payment reference: %w", err)
	}

	log.Printf("Created Conekta checkout %s for order %s", result.ID, orderID)
	return &CheckoutSession{
		CheckoutURL:    result.Checkout.URL,
		CheckoutID:     result.Checkout.ID,
		ConektaOrderID: result.ID,
	}, nil
}

// conektaRequest performs an authenticated request to the Conekta API v2
func (s *PaymentService) conektaRequest(ctx context.Context, method, path string, body []byte) (*http.Response, error) {
	var reader io.Reader
	if body != nil {
		reader = bytes.NewReader(body)
	}

	req, err := http.NewRequestWithContext(ctx, method, conektaAPIBase+path, reader)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+s.conektaSecretKey)
	req.Header.Set("Accept", "application/vnd.conekta-v2.2.0+json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept-Language", "es")
	req.Header.Set("X-Conekta-Idempotency", fmt.Sprintf("mdomio-%d", time.Now().UnixNano()))

	client := &http.Client{Timeout: 30 * time.Second}
	return client.Do(req)
}

// ValidateConektaWebhookSignature verifies the Conekta DIGEST header (RSA-SHA256)
// over the raw request body. In demo mode (no public key configured) it accepts.
func (s *PaymentService) ValidateConektaWebhookSignature(payload []byte, signature string) error {
	if s.conektaWebhookPublicKey == "" {
		log.Printf("[conekta-webhook] no public key configured; accepting webhook without signature")
		return nil
	}

	sig, err := base64.StdEncoding.DecodeString(signature)
	if err != nil {
		return fmt.Errorf("invalid webhook signature encoding: %w", err)
	}

	block, _ := pem.Decode([]byte(s.conektaWebhookPublicKey))
	if block == nil {
		return fmt.Errorf("invalid webhook public key PEM")
	}

	pub, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return fmt.Errorf("failed to parse webhook public key: %w", err)
	}

	rsaPub, ok := pub.(*rsa.PublicKey)
	if !ok {
		return fmt.Errorf("webhook public key is not an RSA key")
	}

	hashed := sha256.Sum256(payload)
	if err := rsa.VerifyPKCS1v15(rsaPub, crypto.SHA256, hashed[:], sig); err != nil {
		return fmt.Errorf("webhook signature verification failed: %w", err)
	}

	return nil
}

// HandleConektaWebhook processes a Conekta webhook event. Returns the event type.
func (s *PaymentService) HandleConektaWebhook(ctx context.Context, payload []byte) (string, error) {
	var event struct {
		ID   string `json:"id"`
		Type string `json:"type"`
		Data struct {
			Object struct {
				ID      string `json:"id"`
				Status  string `json:"status"`
				Amount  int    `json:"amount"`
				Charges struct {
					Data []struct {
						ID            string `json:"id"`
						PaymentMethod struct {
							Type string `json:"type"`
						} `json:"payment_method"`
					} `json:"data"`
				} `json:"charges"`
			} `json:"object"`
		} `json:"data"`
	}
	if err := json.Unmarshal(payload, &event); err != nil {
		return "", fmt.Errorf("failed to parse webhook payload: %w", err)
	}

	if event.Type != "order.paid" {
		return event.Type, nil
	}

	conektaOrderID := event.Data.Object.ID
	if conektaOrderID == "" {
		return event.Type, fmt.Errorf("webhook missing conekta order id")
	}

	order, err := s.orderService.GetOrderByConektaID(ctx, conektaOrderID)
	if err != nil {
		return event.Type, fmt.Errorf("failed to resolve conekta order: %w", err)
	}

	// Deduplicate: already paid → acknowledge without reprocessing
	if order.Status == models.OrderStatusPaid {
		log.Printf("[conekta-webhook] order %s already paid; skipping duplicate (event %s)", order.ID.Hex(), event.ID)
		return event.Type, nil
	}

	paymentMethod := "card"
	chargeID := ""
	if len(event.Data.Object.Charges.Data) > 0 {
		paymentMethod = event.Data.Object.Charges.Data[0].PaymentMethod.Type
		chargeID = event.Data.Object.Charges.Data[0].ID
	}

	paymentInfo := map[string]interface{}{
		"provider":         "conekta",
		"conekta_order_id": conektaOrderID,
		"charge_id":        chargeID,
		"payment_method":   paymentMethod,
		"amount":           float64(event.Data.Object.Amount) / 100,
		"currency":         "MXN",
		"status":           "completed",
		"processed_at":     time.Now().Format(time.RFC3339),
		"webhook_event_id": event.ID,
	}

	if err := s.orderService.UpdateOrderPayment(ctx, order.ID.Hex(), paymentInfo); err != nil {
		return event.Type, fmt.Errorf("failed to mark order paid: %w", err)
	}

	log.Printf("[conekta-webhook] order %s marked paid via %s (event %s)", order.ID.Hex(), paymentMethod, event.ID)
	return event.Type, nil
}
