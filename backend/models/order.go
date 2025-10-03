package models

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// OrderStatus represents the status of an order
type OrderStatus string

const (
	OrderStatusPending   OrderStatus = "pending"
	OrderStatusPaid      OrderStatus = "paid"
	OrderStatusShipped   OrderStatus = "shipped"
	OrderStatusCompleted OrderStatus = "completed"
	OrderStatusCancelled OrderStatus = "cancelled"
)

// OrderItem represents an item in an order
type OrderItem struct {
	ProductID primitive.ObjectID `bson:"productId" json:"productId"`
	VariantID string             `bson:"variantId,omitempty" json:"variantId,omitempty"`
	Quantity  int                `bson:"quantity" json:"quantity"`
	Price     float64            `bson:"price" json:"price"`
	Rebate    float64            `bson:"rebate,omitempty" json:"rebate,omitempty"`

	// Denormalized product info for order history
	ProductName string `bson:"productName,omitempty" json:"productName,omitempty"`
	ImageURL    string `bson:"imageUrl,omitempty" json:"imageUrl,omitempty"`
}

// Order represents an order in the system
type Order struct {
	ID          primitive.ObjectID     `bson:"_id,omitempty" json:"id,omitempty"`
	UserID      primitive.ObjectID     `bson:"userId" json:"userId"`
	Items       []OrderItem            `bson:"items" json:"items"`
	Total       float64                `bson:"total" json:"total"`
	Status      OrderStatus            `bson:"status" json:"status"`
	PaymentInfo map[string]interface{} `bson:"paymentInfo,omitempty" json:"paymentInfo,omitempty"`

	// Timestamps
	CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time `bson:"updatedAt" json:"updatedAt"`
}

// OrderResponse represents order data returned to client
type OrderResponse struct {
	ID          primitive.ObjectID     `json:"id"`
	UserID      primitive.ObjectID     `json:"userId"`
	Items       []OrderItem            `json:"items"`
	Total       float64                `json:"total"`
	Status      OrderStatus            `json:"status"`
	PaymentInfo map[string]interface{} `json:"paymentInfo,omitempty"`
	CreatedAt   time.Time              `json:"createdAt"`
	UpdatedAt   time.Time              `json:"updatedAt"`
}

// OrderCreateRequest represents a request to create an order
type OrderCreateRequest struct {
	CartID      string                 `json:"cartId"`
	PaymentInfo map[string]interface{} `json:"paymentInfo,omitempty"`
}

// OrderUpdateRequest represents a request to update an order
type OrderUpdateRequest struct {
	Status      OrderStatus            `json:"status,omitempty"`
	PaymentInfo map[string]interface{} `json:"paymentInfo,omitempty"`
}

// ToResponse converts Order to OrderResponse
func (o *Order) ToResponse() *OrderResponse {
	return &OrderResponse{
		ID:          o.ID,
		UserID:      o.UserID,
		Items:       o.Items,
		Total:       o.Total,
		Status:      o.Status,
		PaymentInfo: o.PaymentInfo,
		CreatedAt:   o.CreatedAt,
		UpdatedAt:   o.UpdatedAt,
	}
}

// CanTransitionTo checks if an order can transition from its current status to a new status
func (o *Order) CanTransitionTo(newStatus OrderStatus) bool {
	switch o.Status {
	case OrderStatusPending:
		return newStatus == OrderStatusPaid || newStatus == OrderStatusCancelled
	case OrderStatusPaid:
		return newStatus == OrderStatusShipped || newStatus == OrderStatusCancelled
	case OrderStatusShipped:
		return newStatus == OrderStatusCompleted
	case OrderStatusCompleted:
		return false // Completed orders cannot transition
	case OrderStatusCancelled:
		return false // Cancelled orders cannot transition
	default:
		return false
	}
}

// IsActive returns true if the order is still processing
func (o *Order) IsActive() bool {
	return o.Status == OrderStatusPending || o.Status == OrderStatusPaid || o.Status == OrderStatusShipped
}

// Validate validates the order data
func (o *Order) Validate() error {
	if o.UserID.IsZero() {
		return fmt.Errorf("user ID is required")
	}
	if len(o.Items) == 0 {
		return fmt.Errorf("at least one item is required")
	}
	if o.Total <= 0 {
		return fmt.Errorf("total must be greater than zero")
	}

	for i, item := range o.Items {
		if item.ProductID.IsZero() {
			return fmt.Errorf("item %d: product ID is required", i)
		}
		if item.Quantity <= 0 {
			return fmt.Errorf("item %d: quantity must be greater than zero", i)
		}
		if item.Price < 0 {
			return fmt.Errorf("item %d: price must be non-negative", i)
		}
	}

	return nil
}

// CalculateTotal recalculates the total from items
func (o *Order) CalculateTotal() {
	total := 0.0
	for _, item := range o.Items {
		total += item.Price * float64(item.Quantity)
	}
	o.Total = total
}
