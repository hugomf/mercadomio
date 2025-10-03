package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UserType represents the type of user
type UserType string

const (
	UserTypeIndividual UserType = "individual"
	UserTypeWholesale  UserType = "wholesale"
)

// User represents a user in the system
type User struct {
	ID               primitive.ObjectID     `bson:"_id,omitempty" json:"id,omitempty"`
	Email            string                 `bson:"email" json:"email" validate:"required,email"`
	PasswordHash     string                 `bson:"passwordHash" json:"-" validate:"required"`
	Name             string                 `bson:"name" json:"name" validate:"required"`
	OrderHistory     []primitive.ObjectID   `bson:"orderHistory" json:"orderHistory,omitempty"`
	RebateCredits    float64                `bson:"rebateCredits" json:"rebateCredits,omitempty"`
	Type             UserType               `bson:"type" json:"type" validate:"required,oneof=individual wholesale"`
	CustomAttributes map[string]interface{} `bson:"customAttributes,omitempty" json:"customAttributes,omitempty"`

	// New shopping profile features
	Addresses      []Address       `bson:"addresses" json:"addresses,omitempty"`
	PaymentMethods []PaymentMethod `bson:"paymentMethods" json:"paymentMethods,omitempty"`
	Wishlist       []string        `bson:"wishlist" json:"wishlist,omitempty"`

	// Timestamps
	CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time `bson:"updatedAt" json:"updatedAt"`
}

// UserLoginRequest represents a user login request
type UserLoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
}

// UserRegisterRequest represents a user registration request
type UserRegisterRequest struct {
	Email    string   `json:"email" validate:"required,email"`
	Password string   `json:"password" validate:"required,min=6"`
	Name     string   `json:"name" validate:"required"`
	Type     UserType `json:"type" validate:"required,oneof=individual wholesale"`
}

// UserResponse represents user data returned to client (without sensitive info)
type UserResponse struct {
	ID            primitive.ObjectID `json:"id"`
	Email         string             `json:"email"`
	Name          string             `json:"name"`
	Type          UserType           `json:"type"`
	RebateCredits float64            `json:"rebateCredits"`
	CreatedAt     time.Time          `json:"createdAt"`
	UpdatedAt     time.Time          `json:"updatedAt"`
}

// ToResponse converts User to UserResponse
func (u *User) ToResponse() *UserResponse {
	return &UserResponse{
		ID:            u.ID,
		Email:         u.Email,
		Name:          u.Name,
		Type:          u.Type,
		RebateCredits: u.RebateCredits,
		CreatedAt:     u.CreatedAt,
		UpdatedAt:     u.UpdatedAt,
	}
}

type Address struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Type         string             `bson:"type" json:"type"` // shipping, billing
	FirstName    string             `bson:"firstName" json:"firstName"`
	LastName     string             `bson:"lastName" json:"lastName"`
	Company      string             `bson:"company" json:"company,omitempty"`
	AddressLine1 string             `bson:"addressLine1" json:"addressLine1"`
	AddressLine2 string             `bson:"addressLine2" json:"addressLine2,omitempty"`
	City         string             `bson:"city" json:"city"`
	State        string             `bson:"state" json:"state"`
	PostalCode   string             `bson:"postalCode" json:"postalCode"`
	Country      string             `bson:"country" json:"country"`
	Phone        string             `bson:"phone" json:"phone,omitempty"`
	IsDefault    bool               `bson:"isDefault" json:"isDefault"`
	CreatedAt    time.Time          `bson:"createdAt" json:"createdAt"`
}

type PaymentMethod struct {
	ID              primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Type            string             `bson:"type" json:"type"`                       // card, paypal, etc.
	Provider        string             `bson:"provider" json:"provider"`               // stripe, paypal
	PaymentMethodID string             `bson:"paymentMethodId" json:"paymentMethodId"` // Stripe payment method ID
	Last4           string             `bson:"last4" json:"last4,omitempty"`
	Brand           string             `bson:"brand" json:"brand,omitempty"`
	ExpiryMonth     int                `bson:"expiryMonth" json:"expiryMonth,omitempty"`
	ExpiryYear      int                `bson:"expiryYear" json:"expiryYear,omitempty"`
	IsDefault       bool               `bson:"isDefault" json:"isDefault"`
	CreatedAt       time.Time          `bson:"createdAt" json:"createdAt"`
}
