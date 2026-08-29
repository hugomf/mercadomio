package services

import (
	"context"
	"errors"
	"fmt"
	"mercadomio-backend/models"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

const (
	userCollectionName = "users"
)

// AuthService manages local user records resolved from OIDC identities.
type AuthService struct {
	db        *mongo.Database
	jwtSecret string
}

// NewAuthService creates a new auth service
func NewAuthService(db *mongo.Database) *AuthService {
	return &AuthService{db: db}
}

// SyncUser resolves the local user for a validated OIDC identity:
// 1. match by userbrewSub, 2. link an existing local user by email,
// 3. create a new user as last resort.
func (s *AuthService) SyncUser(sub, email, name string) (*models.User, error) {
	if sub == "" {
		return nil, errors.New("empty subject claim")
	}
	if email == "" {
		return nil, errors.New("token has no email claim")
	}

	col := s.db.Collection(userCollectionName)
	ctx := context.Background()
	now := time.Now()

	var user models.User

	// 1. Already linked to this identity.
	err := col.FindOne(ctx, bson.M{"userbrewSub": sub}).Decode(&user)
	if err == nil {
		return &user, nil
	}
	if !errors.Is(err, mongo.ErrNoDocuments) {
		return nil, fmt.Errorf("failed to look up user by subject: %w", err)
	}

	// 2. Existing local account with the same email: link it.
	err = col.FindOneAndUpdate(
		ctx,
		bson.M{"email": email, "userbrewSub": bson.M{"$in": bson.A{nil, ""}}},
		bson.M{"$set": bson.M{"userbrewSub": sub, "updatedAt": now}},
	).Decode(&user)
	if err == nil {
		return &user, nil
	}
	if !errors.Is(err, mongo.ErrNoDocuments) {
		return nil, fmt.Errorf("failed to link user by email: %w", err)
	}

	// 3. Brand new customer.
	user = models.User{
		ID:               primitive.NewObjectID(),
		Email:            email,
		Name:             name,
		UserbrewSub:      sub,
		Type:             models.UserTypeIndividual,
		OrderHistory:     []primitive.ObjectID{},
		CustomAttributes: map[string]interface{}{},
		CreatedAt:        now,
		UpdatedAt:        now,
	}
	if _, err := col.InsertOne(ctx, &user); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}
	return &user, nil
}

// GetUserByID retrieves a user by ID
func (s *AuthService) GetUserByID(userID string) (*models.User, error) {
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID: %w", err)
	}

	user, err := s.findUserByFilter(bson.M{"_id": objID})
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}

	return user, nil
}

// UpdateUser updates user information
func (s *AuthService) UpdateUser(userID string, updates bson.M) error {
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	updates["updatedAt"] = time.Now()

	filter := bson.M{"_id": objID}
	update := bson.M{"$set": updates}

	result, err := s.db.Collection(userCollectionName).UpdateOne(context.Background(), filter, update)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	if result.ModifiedCount == 0 {
		return errors.New("user not updated")
	}

	return nil
}

// Helper methods

func (s *AuthService) findUserByFilter(filter bson.M) (*models.User, error) {
	var user models.User
	err := s.db.Collection(userCollectionName).FindOne(context.Background(), filter).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("user not found")
		}
		return nil, fmt.Errorf("failed to find user: %w", err)
	}
	return &user, nil
}

// AddUserAddress adds a new address to user's profile
func (s *AuthService) AddUserAddress(userID string, address *models.Address) error {
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	// Set creation timestamp
	address.CreatedAt = time.Now()

	filter := bson.M{"_id": objID}
	update := bson.M{"$push": bson.M{"addresses": address}}

	result, err := s.db.Collection(userCollectionName).UpdateOne(context.Background(), filter, update)
	if err != nil {
		return fmt.Errorf("failed to add address: %w", err)
	}

	if result.ModifiedCount == 0 {
		return errors.New("user not updated")
	}

	return nil
}

// AddUserPaymentMethod adds a new payment method to user's profile
func (s *AuthService) AddUserPaymentMethod(userID string, paymentMethod *models.PaymentMethod) error {
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	filter := bson.M{"_id": objID}
	update := bson.M{"$push": bson.M{"paymentMethods": paymentMethod}}

	result, err := s.db.Collection(userCollectionName).UpdateOne(context.Background(), filter, update)
	if err != nil {
		return fmt.Errorf("failed to add payment method: %w", err)
	}

	if result.ModifiedCount == 0 {
		return errors.New("user not updated")
	}

	return nil
}

// AddToUserWishlist adds a product to user's wishlist
func (s *AuthService) AddToUserWishlist(userID string, productID string) error {
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	filter := bson.M{"_id": objID, "wishlist": bson.M{"$ne": productID}}
	update := bson.M{"$push": bson.M{"wishlist": productID}}

	result, err := s.db.Collection(userCollectionName).UpdateOne(context.Background(), filter, update)
	if err != nil {
		return fmt.Errorf("failed to add to wishlist: %w", err)
	}

	if result.ModifiedCount == 0 {
		return errors.New("product already in wishlist or user not found")
	}

	return nil
}

// RemoveFromUserWishlist removes a product from user's wishlist
func (s *AuthService) RemoveFromUserWishlist(userID string, productID string) error {
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	filter := bson.M{"_id": objID}
	update := bson.M{"$pull": bson.M{"wishlist": productID}}

	result, err := s.db.Collection(userCollectionName).UpdateOne(context.Background(), filter, update)
	if err != nil {
		return fmt.Errorf("failed to remove from wishlist: %w", err)
	}

	if result.ModifiedCount == 0 {
		return errors.New("product not in wishlist or user not found")
	}

	return nil
}
