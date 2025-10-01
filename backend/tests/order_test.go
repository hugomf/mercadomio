// NOTE: Full service tests will be added after OrderService is implemented.
// For now, we test the Order model validation and status transitions.

package tests

import (
	"testing"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"mercadomio-backend/models"
)

// TestOrderModel tests the Order model functionality
func TestOrderModelValidation(t *testing.T) {
	// Test order validation with valid data
	order := &models.Order{
		UserID: primitive.NewObjectID(),
		Items: []models.OrderItem{
			{
				ProductID: primitive.NewObjectID(),
				Quantity:  2,
				Price:     29.99,
			},
		},
		Total: 59.98,
	}

	err := order.Validate()
	if err != nil {
		t.Errorf("Valid order failed validation: %v", err)
	}

	// Test order without user ID
	order.UserID = primitive.NilObjectID
	err = order.Validate()
	if err == nil {
		t.Errorf("Expected error for order without user ID")
	}

	// Test order without items
	order.UserID = primitive.NewObjectID()
	order.Items = []models.OrderItem{}
	err = order.Validate()
	if err == nil {
		t.Errorf("Expected error for order without items")
	}

	// Test order with zero total
	order.Items = []models.OrderItem{
		{
			ProductID: primitive.NewObjectID(),
			Quantity:  1,
			Price:     0,
		},
	}
	order.Total = 0
	err = order.Validate()
	if err == nil {
		t.Errorf("Expected error for order with zero total")
	}
}

func TestOrderModelCalculateTotal(t *testing.T) {
	order := &models.Order{
		Items: []models.OrderItem{
			{
				ProductID: primitive.NewObjectID(),
				Quantity:  2,
				Price:     10.00,
			},
			{
				ProductID: primitive.NewObjectID(),
				Quantity:  1,
				Price:     15.50,
			},
		},
	}

	order.CalculateTotal()

	expectedTotal := 35.50 // (2 * 10.00) + (1 * 15.50)
	if order.Total != expectedTotal {
		t.Errorf("Expected total %f, got %f", expectedTotal, order.Total)
	}
}

func TestOrderStatusTransitions(t *testing.T) {
	// Test the Order model's transition logic (this doesn't depend on service)

	order := &models.Order{Status: models.OrderStatusPending}

	// Valid transitions from pending
	if !order.CanTransitionTo(models.OrderStatusPaid) {
		t.Errorf("Order should be able to transition from pending to paid")
	}
	if !order.CanTransitionTo(models.OrderStatusCancelled) {
		t.Errorf("Order should be able to transition from pending to cancelled")
	}
	if order.CanTransitionTo(models.OrderStatusShipped) {
		t.Errorf("Order should NOT be able to transition from pending to shipped")
	}

	order.Status = models.OrderStatusPaid
	// Valid transitions from paid
	if !order.CanTransitionTo(models.OrderStatusShipped) {
		t.Errorf("Order should be able to transition from paid to shipped")
	}
	if !order.CanTransitionTo(models.OrderStatusCancelled) {
		t.Errorf("Order should be able to transition from paid to cancelled")
	}
	if order.CanTransitionTo(models.OrderStatusCompleted) {
		t.Errorf("Order should NOT be able to transition from paid to completed")
	}

	order.Status = models.OrderStatusCompleted
	// No valid transitions from completed
	if order.CanTransitionTo(models.OrderStatusPaid) {
		t.Errorf("Order should NOT be able to transition from completed to paid")
	}
	if order.CanTransitionTo(models.OrderStatusShipped) {
		t.Errorf("Order should NOT be able to transition from completed to shipped")
	}
}
