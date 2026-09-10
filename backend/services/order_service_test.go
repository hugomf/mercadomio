//go:build integration
// +build integration

package services

import (
	"context"
	"testing"
	"time"

	"mercadomio-backend/models"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// TestOrderPaymentWebhookDedup verifies that UpdateOrderPayment does not
// perform a redundant status transition when the order is already paid,
// which prevents double-processing of conekta webhook events.
func TestOrderPaymentWebhookDedup(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI("mongodb://localhost:27017"))
	if err != nil {
		t.Skipf("mongo unavailable: %v", err)
	}
	defer client.Disconnect(ctx)

	db := client.Database("mercadomio_test")
	t.Cleanup(func() { _ = db.Collection("orders").Drop(context.Background()) })

	svc := NewOrderService(db)
	uid := primitive.NewObjectID()
	order := &models.Order{
		UserID:  uid,
		Items:   []models.OrderItem{{ProductID: primitive.NewObjectID(), Quantity: 1, Price: 10.0}},
		Total:   10.0,
		Status:  models.OrderStatusPending,
	}
	_, err = svc.(*OrderService).collection.InsertOne(ctx, order)
	if err != nil {
		t.Fatalf("insert order: %v", err)
	}

	paymentInfo := map[string]interface{}{
		"provider": "conekta",
		"status":   "completed",
	}

	if err := svc.UpdateOrderPayment(ctx, order.ID.Hex(), paymentInfo); err != nil {
		t.Fatalf("first UpdateOrderPayment: %v", err)
	}

	// Second call should be idempotent — no double transition error
	if err := svc.UpdateOrderPayment(ctx, order.ID.Hex(), paymentInfo); err != nil {
		t.Fatalf("second UpdateOrderPayment (dedup): %v", err)
	}

	got, _ := svc.GetOrderByID(ctx, order.ID.Hex())
	if got.Status != models.OrderStatusPaid {
		t.Fatalf("expected Paid, got %s", got.Status)
	}
}
