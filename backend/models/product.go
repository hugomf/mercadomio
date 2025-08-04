package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Product struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Name        string             `bson:"name" json:"name"`
	Description string             `bson:"description" json:"description"`
	Price       float64            `bson:"price" json:"price"`
	SKU         string             `bson:"sku" json:"sku"`
	Category    string             `bson:"category" json:"category"`
	Variants    []Variant          `bson:"variants" json:"variants"`
	CreatedAt   time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt   time.Time          `bson:"updatedAt" json:"updatedAt"`
}

type Variant struct {
	VariantID   string  `bson:"variantId" json:"variantId"`
	Name        string  `bson:"name" json:"name"`
	Price       float64 `bson:"price" json:"price"`
	Stock       int     `bson:"stock" json:"stock"`
	SKU         string  `bson:"sku" json:"sku"`
	ImageURL    string  `bson:"imageUrl" json:"imageUrl"`
	IsAvailable bool    `bson:"isAvailable" json:"isAvailable"`
}
