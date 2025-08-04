package services

import "time"

// DomainEvent represents a business event that occurred in the system
type DomainEvent interface {
	EventType() string
	AggregateID() string
	OccurredAt() time.Time
}

// CartItemAdded represents when an item is added to a cart
type CartItemAdded struct {
	CartID    string                 `json:"cartId"`
	ProductID string                 `json:"productId"`
	VariantID string                 `json:"variantId,omitempty"`
	UserID    string                 `json:"userId"`
	Quantity  int                    `json:"quantity"`
	Value     float64                `json:"value"`
	Timestamp time.Time              `json:"timestamp"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

func (e CartItemAdded) EventType() string     { return "cart.item.added" }
func (e CartItemAdded) AggregateID() string   { return e.CartID }
func (e CartItemAdded) OccurredAt() time.Time { return e.Timestamp }

// CartItemRemoved represents when an item is removed from a cart
type CartItemRemoved struct {
	CartID    string                 `json:"cartId"`
	ProductID string                 `json:"productId"`
	VariantID string                 `json:"variantId,omitempty"`
	UserID    string                 `json:"userId"`
	Quantity  int                    `json:"quantity"`
	Value     float64                `json:"value"`
	Timestamp time.Time              `json:"timestamp"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

func (e CartItemRemoved) EventType() string     { return "cart.item.removed" }
func (e CartItemRemoved) AggregateID() string   { return e.CartID }
func (e CartItemRemoved) OccurredAt() time.Time { return e.Timestamp }

// CartItemUpdated represents when an item quantity is updated in a cart
type CartItemUpdated struct {
	CartID      string                 `json:"cartId"`
	ProductID   string                 `json:"productId"`
	VariantID   string                 `json:"variantId,omitempty"`
	UserID      string                 `json:"userId"`
	OldQuantity int                    `json:"oldQuantity"`
	NewQuantity int                    `json:"newQuantity"`
	ValueChange float64                `json:"valueChange"`
	Timestamp   time.Time              `json:"timestamp"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

func (e CartItemUpdated) EventType() string     { return "cart.item.updated" }
func (e CartItemUpdated) AggregateID() string   { return e.CartID }
func (e CartItemUpdated) OccurredAt() time.Time { return e.Timestamp }

// CartAbandoned represents when a cart is abandoned (inactive for too long)
type CartAbandoned struct {
	CartID    string    `json:"cartId"`
	UserID    string    `json:"userId"`
	Value     float64   `json:"value"`
	ItemCount int       `json:"itemCount"`
	Timestamp time.Time `json:"timestamp"`
}

func (e CartAbandoned) EventType() string     { return "cart.abandoned" }
func (e CartAbandoned) AggregateID() string   { return e.CartID }
func (e CartAbandoned) OccurredAt() time.Time { return e.Timestamp }

// CartConverted represents when a cart is converted to an order
type CartConverted struct {
	CartID    string    `json:"cartId"`
	OrderID   string    `json:"orderId"`
	UserID    string    `json:"userId"`
	Value     float64   `json:"value"`
	ItemCount int       `json:"itemCount"`
	Timestamp time.Time `json:"timestamp"`
}

func (e CartConverted) EventType() string     { return "cart.converted" }
func (e CartConverted) AggregateID() string   { return e.CartID }
func (e CartConverted) OccurredAt() time.Time { return e.Timestamp }

// CartMerged represents when two carts are merged
type CartMerged struct {
	GuestCartID string    `json:"guestCartId"`
	UserCartID  string    `json:"userCartId"`
	UserID      string    `json:"userId"`
	ItemCount   int       `json:"itemCount"`
	Value       float64   `json:"value"`
	Timestamp   time.Time `json:"timestamp"`
}

func (e CartMerged) EventType() string     { return "cart.merged" }
func (e CartMerged) AggregateID() string   { return e.UserCartID }
func (e CartMerged) OccurredAt() time.Time { return e.Timestamp }

// ProductViewed represents when a product is viewed
type ProductViewed struct {
	ProductID string                 `json:"productId"`
	UserID    string                 `json:"userId"`
	SessionID string                 `json:"sessionId,omitempty"`
	Source    string                 `json:"source"` // "search", "category", "direct", etc.
	Timestamp time.Time              `json:"timestamp"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

func (e ProductViewed) EventType() string     { return "product.viewed" }
func (e ProductViewed) AggregateID() string   { return e.ProductID }
func (e ProductViewed) OccurredAt() time.Time { return e.Timestamp }
