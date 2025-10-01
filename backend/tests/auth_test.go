package tests

import (
	"context"
	"testing"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"mercadomio-backend/models"
	"mercadomio-backend/services"
)

// TestAuthServiceRegister tests user registration
func TestAuthServiceRegister(t *testing.T) {
	// Setup test database
	mongoURI := "mongodb://localhost:27017"
	client, err := mongo.Connect(context.Background(), options.Client().ApplyURI(mongoURI))
	if err != nil {
		t.Fatal(err)
	}
	defer client.Disconnect(context.Background())

	db := client.Database("mercadomio_test")
	// Clean test data
	db.Collection("users").Drop(context.Background())

	// Create auth service
	authService := services.NewAuthService(db)

	req := &models.UserRegisterRequest{
		Email:    "test@example.com",
		Password: "password123",
		Name:     "Test User",
		Type:     models.UserTypeIndividual,
	}

	user, err := authService.Register(req)
	if err != nil {
		t.Errorf("Registration failed: %v", err)
	}
	if user == nil {
		t.Error("User is nil")
	}
	if user.Email != "test@example.com" {
		t.Errorf("Expected email test@example.com, got %s", user.Email)
	}
	if user.Name != "Test User" {
		t.Errorf("Expected name Test User, got %s", user.Name)
	}
	if user.Type != models.UserTypeIndividual {
		t.Errorf("Expected type individual, got %v", user.Type)
	}

	// Test duplicate email registration
	_, err = authService.Register(req)
	if err == nil {
		t.Error("Expected error for duplicate email")
	}
}

// TestAuthServiceLogin tests user authentication
func TestAuthServiceLogin(t *testing.T) {
	// Setup test database
	mongoURI := "mongodb://localhost:27017"
	client, err := mongo.Connect(context.Background(), options.Client().ApplyURI(mongoURI))
	if err != nil {
		t.Fatal(err)
	}
	defer client.Disconnect(context.Background())

	db := client.Database("mercadomio_test")
	// Clean test data
	db.Collection("users").Drop(context.Background())

	// Create auth service
	authService := services.NewAuthService(db)

	// First register a user
	req := &models.UserRegisterRequest{
		Email:    "login@test.com",
		Password: "password123",
		Name:     "Login User",
		Type:     models.UserTypeIndividual,
	}

	_, err = authService.Register(req)
	if err != nil {
		t.Fatal(err)
	}

	// Test successful login
	loginReq := &models.UserLoginRequest{
		Email:    "login@test.com",
		Password: "password123",
	}

	authResponse, err := authService.Login(loginReq)
	if err != nil {
		t.Errorf("Login failed: %v", err)
	}
	if authResponse == nil {
		t.Error("Auth response is nil")
	}
	if authResponse.Token == "" {
		t.Error("Token is empty")
	}
	if authResponse.User.Name != "Login User" {
		t.Errorf("Expected name Login User, got %s", authResponse.User.Name)
	}

	// Test invalid password
	loginReq.Password = "wrongpassword"
	_, err = authService.Login(loginReq)
	if err == nil {
		t.Error("Expected error for invalid password")
	}

	// Test non-existent user
	loginReq.Email = "nonexistent@test.com"
	_, err = authService.Login(loginReq)
	if err == nil {
		t.Error("Expected error for non-existent user")
	}
}

// TestAuthServiceValidateToken tests JWT token validation
func TestAuthServiceValidateToken(t *testing.T) {
	// Setup test database
	mongoURI := "mongodb://localhost:27017"
	client, err := mongo.Connect(context.Background(), options.Client().ApplyURI(mongoURI))
	if err != nil {
		t.Fatal(err)
	}
	defer client.Disconnect(context.Background())

	db := client.Database("mercadomio_test")
	// Clean test data
	db.Collection("users").Drop(context.Background())

	// Create auth service
	authService := services.NewAuthService(db)

	// Register and login first
	req := &models.UserRegisterRequest{
		Email:    "token@test.com",
		Password: "password123",
		Name:     "Token User",
		Type:     models.UserTypeWholesale,
	}

	_, err = authService.Register(req)
	if err != nil {
		t.Fatal(err)
	}

	loginReq := &models.UserLoginRequest{
		Email:    "token@test.com",
		Password: "password123",
	}

	authResponse, err := authService.Login(loginReq)
	if err != nil {
		t.Fatal(err)
	}

	// Validate the token
	claims, err := authService.ValidateToken(authResponse.Token)
	if err != nil {
		t.Errorf("Token validation failed: %v", err)
	}
	if claims.Email != "token@test.com" {
		t.Errorf("Expected email token@test.com, got %s", claims.Email)
	}
	if claims.Type != models.UserTypeWholesale {
		t.Errorf("Expected type wholesale, got %v", claims.Type)
	}
	if claims.UserID == "" {
		t.Error("UserID is empty")
	}

	// Test invalid token
	_, err = authService.ValidateToken("invalid.jwt.token")
	if err == nil {
		t.Error("Expected error for invalid token")
	}
}
