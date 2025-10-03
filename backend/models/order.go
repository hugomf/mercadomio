package models

import (
<<<<<<< Updated upstream
	"fmt"
=======
>>>>>>> Stashed changes
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

<<<<<<< Updated upstream
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
=======
type Order struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	CustomerID   primitive.ObjectID `bson:"customerId" json:"customerId"`
	CustomerName string             `bson:"customerName" json:"customerName"`
	CustomerEmail string            `bson:"customerEmail" json:"customerEmail"`
	Items        []OrderItem        `bson:"items" json:"items"`
	TotalAmount  float64            `bson:"totalAmount" json:"totalAmount"`
	Status       string             `bson:"status" json:"status"` // pending, processing, shipped, delivered, cancelled
	ShippingAddress Address         `bson:"shippingAddress" json:"shippingAddress"`
	CreatedAt    time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt    time.Time          `bson:"updatedAt" json:"updatedAt"`
}

type OrderItem struct {
	ProductID   primitive.ObjectID `bson:"productId" json:"productId"`
	ProductName string             `bson:"productName" json:"productName"`
	VariantID   string             `bson:"variantId,omitempty" json:"variantId,omitempty"`
	VariantName string             `bson:"variantName,omitempty" json:"variantName,omitempty"`
	Quantity    int                `bson:"quantity" json:"quantity"`
	UnitPrice   float64            `bson:"unitPrice" json:"unitPrice"`
	TotalPrice  float64            `bson:"totalPrice" json:"totalPrice"`
}

type Address struct {
	Street     string `bson:"street" json:"street"`
	City       string `bson:"city" json:"city"`
	State      string `bson:"state" json:"state"`
	PostalCode string `bson:"postalCode" json:"postalCode"`
	Country    string `bson:"country" json:"country"`
}
>>>>>>> Stashed changes
