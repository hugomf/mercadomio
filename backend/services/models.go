package services

import (
	"encoding/json"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Product events
const (
	EventProductCreated = "product.created"
	EventProductUpdated = "product.updated"
	EventProductDeleted = "product.deleted"
	EventVariantAdded   = "variant.added"
	EventVariantUpdated = "variant.updated"
	EventVariantRemoved = "variant.removed"
)

// Event represents a domain event
type Event struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

// Variant represents a product variant
type Variant struct {
	VariantID       string                 `bson:"variantId" json:"variantId" validate:"required"`
	Attributes      map[string]interface{} `bson:"attributes" json:"attributes"`
	PriceAdjustment float64                `bson:"priceAdjustment" json:"priceAdjustment"`
	SKU             string                 `bson:"sku" json:"sku" validate:"required"`
	Barcode         string                 `bson:"barcode" json:"barcode"`
	Stock           int                    `bson:"stock" json:"stock"`
}

// Category represents a product category
type Category struct {
	ID          primitive.ObjectID   `bson:"_id,omitempty" json:"id"`
	Name        string               `bson:"name" json:"name" validate:"required"`
	Slug        string               `bson:"slug" json:"slug" validate:"required"`
	Description string               `bson:"description" json:"description"`
	ParentID    *primitive.ObjectID  `bson:"parentId,omitempty" json:"parentId"`
	Children    []primitive.ObjectID `bson:"children" json:"children"`
	ImageURL    string               `bson:"imageUrl" json:"imageUrl"`
	IsActive    bool                 `bson:"isActive" json:"isActive"`
	CreatedAt   time.Time            `bson:"createdAt" json:"createdAt"`
	UpdatedAt   time.Time            `bson:"updatedAt" json:"updatedAt"`
}

// Product represents a product in the store
type Product struct {
	ID               primitive.ObjectID     `bson:"_id,omitempty" json:"id"`
	Name             string                 `bson:"name" json:"name" validate:"required"`
	Description      string                 `bson:"description" json:"description"`
	Type             string                 `bson:"type" json:"type" validate:"required,oneof=physical service subscription"`
	Category         string                 `bson:"category" json:"category"`
	Categories       []primitive.ObjectID   `bson:"categories" json:"categories" validate:"required"`
	BasePrice        float64                `bson:"basePrice" json:"basePrice" validate:"required"`
	SKU              string                 `bson:"sku" json:"sku" validate:"required"`
	Barcode          string                 `bson:"barcode" json:"barcode"`
	ImageURL         string                 `bson:"imageUrl" json:"imageUrl"`
	Variants         []Variant              `bson:"variants" json:"variants"`
	CustomAttributes map[string]interface{} `bson:"customAttributes" json:"customAttributes"`
	Identifiers      map[string]string      `bson:"identifiers" json:"identifiers"`
	CreatedAt        time.Time              `bson:"createdAt" json:"createdAt"`
	UpdatedAt        time.Time              `bson:"updatedAt" json:"updatedAt"`
}

// SearchParams represents search parameters
type SearchParams struct {
	Query             string
	Categories        []string
	MinPrice          float64
	MaxPrice          float64
	Type              string // "physical", "service", or "subscription"
	VariantAttributes map[string]interface{}
	SortBy            string
	SortOrder         string
}

// SearchResult represents search results
type SearchResult struct {
	Data       []Product `json:"data"`
	TotalItems int       `json:"totalItems"`
}

// CartItem represents an item in a cart
type CartItem struct {
	ProductID  string                 `json:"productId"`
	VariantID  string                 `json:"variantId,omitempty"`
	Quantity   int                    `json:"quantity"`
	Attributes map[string]interface{} `json:"attributes,omitempty"`
}

// Cart represents a shopping cart
type Cart struct {
	ID        string     `json:"id"`
	UserID    string     `json:"userId,omitempty"`
	Items     []CartItem `json:"items"`
	CreatedAt time.Time  `json:"createdAt"`
	UpdatedAt time.Time  `json:"updatedAt"`
}

// CartAnalyticsResult represents analytics query results
type CartAnalyticsResult struct {
	Date  string  `json:"date" bson:"_id"`
	Count int     `json:"count" bson:"count"`
	Value float64 `json:"value,omitempty" bson:"value,omitempty"`
}
