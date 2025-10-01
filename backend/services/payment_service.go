package services

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"mercadomio-backend/models"

	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/paymentintent"
)

// PaymentService handles payment processing via Stripe
type PaymentService struct {
	stripeSecretKey string
	stripePublicKey string
	baseURL         string
	orderService    *OrderService
}

// NewPaymentService creates a new payment service
func NewPaymentService(orderService *OrderService) *PaymentService {
	// Initialize Stripe
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
		stripeSecretKey: stripeSecretKey,
		stripePublicKey: stripePublicKey,
		baseURL:         baseURL,
		orderService:    orderService,
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
