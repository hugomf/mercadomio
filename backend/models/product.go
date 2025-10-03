package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Product struct {
	ID              primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Name            string             `bson:"name" json:"name"`
	Description     string             `bson:"description" json:"description"`
	Price           float64            `bson:"price" json:"price"`
	SKU             string             `bson:"sku" json:"sku"`
	Category        string             `bson:"category" json:"category"`
	Images          []ProductImage     `bson:"images" json:"images"`
	Variants        []Variant          `bson:"variants" json:"variants"`
	Reviews         []Review           `bson:"reviews" json:"reviews"`
	AverageRating   float64            `bson:"averageRating" json:"averageRating"`
	ReviewCount     int                `bson:"reviewCount" json:"reviewCount"`
	RelatedProducts []string           `bson:"relatedProducts" json:"relatedProducts"`
	Tags            []string           `bson:"tags" json:"tags"`
	IsActive        bool               `bson:"isActive" json:"isActive"`
	CreatedAt       time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt       time.Time          `bson:"updatedAt" json:"updatedAt"`
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

type ProductImage struct {
	ID      primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	URL     string             `bson:"url" json:"url"`
	AltText string             `bson:"altText" json:"altText"`
	Order   int                `bson:"order" json:"order"`
	IsMain  bool               `bson:"isMain" json:"isMain"`
}

type Review struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID    primitive.ObjectID `bson:"userId" json:"userId"`
	UserName  string             `bson:"userName" json:"userName"`
	Rating    int                `bson:"rating" json:"rating"`
	Comment   string             `bson:"comment" json:"comment"`
	CreatedAt time.Time          `bson:"createdAt" json:"createdAt"`
}
