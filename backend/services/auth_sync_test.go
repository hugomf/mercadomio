package services

import (
	"context"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"mercadomio-backend/models"
)

func newSyncTestService(t *testing.T) *AuthService {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI("mongodb://localhost:27017"))
	if err != nil {
		t.Skipf("mongo unavailable for integration test: %v", err)
	}
	if err := client.Ping(ctx, nil); err != nil {
		t.Skipf("mongo unreachable for integration test: %v", err)
	}
	t.Cleanup(func() {
		_ = client.Database(syncTestDB).Collection(userCollectionName).Drop(context.Background())
		_ = client.Disconnect(context.Background())
	})

	return NewAuthService(client.Database(syncTestDB))
}

const syncTestDB = "mercadomio_sync_test"

func TestSyncUser_CreatesNewUserFromClaims(t *testing.T) {
	svc := newSyncTestService(t)

	user, err := svc.SyncUser("sub-abc", "nuevo@example.com", "Nuevo Usuario")
	if err != nil {
		t.Fatalf("SyncUser failed: %v", err)
	}

	if user.UserbrewSub != "sub-abc" {
		t.Errorf("UserbrewSub = %q, want %q", user.UserbrewSub, "sub-abc")
	}
	if user.Email != "nuevo@example.com" {
		t.Errorf("Email = %q, want %q", user.Email, "nuevo@example.com")
	}
	if user.Name != "Nuevo Usuario" {
		t.Errorf("Name = %q, want %q", user.Name, "Nuevo Usuario")
	}
	if user.Type != models.UserTypeIndividual {
		t.Errorf("Type = %q, want individual", user.Type)
	}
}

func TestSyncUser_LinksExistingLocalUserByEmail(t *testing.T) {
	svc := newSyncTestService(t)

	ctx := context.Background()
	existing := &models.User{
		ID:           primitive.NewObjectID(),
		Email:        "historica@example.com",
		Name:         "Cliente Histórico",
		Type:         models.UserTypeIndividual,
		OrderHistory: []primitive.ObjectID{primitive.NewObjectID()},
		CreatedAt:    time.Now().Add(-72 * time.Hour),
		UpdatedAt:    time.Now().Add(-72 * time.Hour),
	}
	if _, err := svc.db.Collection(userCollectionName).InsertOne(ctx, existing); err != nil {
		t.Fatalf("failed to seed user: %v", err)
	}

	user, err := svc.SyncUser("sub-xyz", "historica@example.com", "Cliente Histórico")
	if err != nil {
		t.Fatalf("SyncUser failed: %v", err)
	}

	if user.ID != existing.ID {
		t.Fatalf("expected existing user %s to be linked, got new user %s", existing.ID.Hex(), user.ID.Hex())
	}
	if len(user.OrderHistory) != 1 {
		t.Errorf("order history lost during link: %d orders", len(user.OrderHistory))
	}

	var doc models.User
	_ = svc.db.Collection(userCollectionName).FindOne(ctx, bson.M{"_id": existing.ID}).Decode(&doc)
	if doc.UserbrewSub != "sub-xyz" {
		t.Errorf("userbrewSub not persisted: %q", doc.UserbrewSub)
	}
}

func TestSyncUser_IsIdempotentPerSub(t *testing.T) {
	svc := newSyncTestService(t)

	first, err := svc.SyncUser("sub-rep", "rep@example.com", "Repetido")
	if err != nil {
		t.Fatalf("first SyncUser failed: %v", err)
	}

	second, err := svc.SyncUser("sub-rep", "rep@example.com", "Repetido Renombrado")
	if err != nil {
		t.Fatalf("second SyncUser failed: %v", err)
	}

	if first.ID != second.ID {
		t.Fatalf("expected same user, got %s then %s", first.ID.Hex(), second.ID.Hex())
	}
}
