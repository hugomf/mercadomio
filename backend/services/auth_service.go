package services

import (
	"context"
	"errors"
	"fmt"
	"log"
	"mercadomio-backend/models"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"golang.org/x/crypto/bcrypt"
)

const (
	jwtExpiration      = 24 * time.Hour     // 24 hours
	refreshTokenExp    = 7 * 24 * time.Hour // 7 days
	userCollectionName = "users"
)

// AuthClaims represents JWT claims
type AuthClaims struct {
	UserID string          `json:"userId"`
	Email  string          `json:"email"`
	Type   models.UserType `json:"type"`
	jwt.RegisteredClaims
}

// AuthResponse represents the authentication response
type AuthResponse struct {
	Token string               `json:"token"`
	User  *models.UserResponse `json:"user"`
}

// AuthService handles user authentication
type AuthService struct {
	db        *mongo.Database
	jwtSecret string
}

// NewAuthService creates a new auth service
func NewAuthService(db *mongo.Database) *AuthService {
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "fallback-secret-change-in-production"
		log.Printf("Warning: Using fallback JWT secret. Set JWT_SECRET environment variable.")
	}

	return &AuthService{
		db:        db,
		jwtSecret: jwtSecret,
	}
}

// Register creates a new user account
func (s *AuthService) Register(req *models.UserRegisterRequest) (*models.User, error) {
	// Check if email already exists
	filter := bson.M{"email": req.Email}
	count, err := s.db.Collection(userCollectionName).CountDocuments(context.Background(), filter)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing user: %w", err)
	}
	if count > 0 {
		return nil, errors.New("user with this email already exists")
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	now := time.Now()

	user := &models.User{
		ID:               primitive.NewObjectID(),
		Email:            req.Email,
		PasswordHash:     string(hashedPassword),
		Name:             req.Name,
		Type:             req.Type,
		OrderHistory:     []primitive.ObjectID{},
		RebateCredits:    0,
		CustomAttributes: map[string]interface{}{},
		CreatedAt:        now,
		UpdatedAt:        now,
	}

	_, err = s.db.Collection(userCollectionName).InsertOne(context.Background(), user)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return user, nil
}

// Login authenticates a user
func (s *AuthService) Login(req *models.UserLoginRequest) (*AuthResponse, error) {
	user, err := s.findUserByEmail(req.Email)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	// Verify password
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password))
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	// Generate JWT token
	token, err := s.generateToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate token: %w", err)
	}

	return &AuthResponse{
		Token: token,
		User:  user.ToResponse(),
	}, nil
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

// ValidateToken validates a JWT token and returns claims
func (s *AuthService) ValidateToken(tokenString string) (*AuthClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &AuthClaims{}, func(token *jwt.Token) (interface{}, error) {
		// Validate signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(s.jwtSecret), nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	if claims, ok := token.Claims.(*AuthClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// Helper methods

func (s *AuthService) findUserByEmail(email string) (*models.User, error) {
	return s.findUserByFilter(bson.M{"email": email})
}

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

func (s *AuthService) generateToken(user *models.User) (string, error) {
	expiration := time.Now().Add(jwtExpiration)

	claims := AuthClaims{
		UserID: user.ID.Hex(),
		Email:  user.Email,
		Type:   user.Type,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiration),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(s.jwtSecret))
	if err != nil {
		return "", err
	}

	return tokenString, nil
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
