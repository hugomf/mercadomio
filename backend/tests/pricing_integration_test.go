package tests

import (
	"context"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"mercadomio-backend/models"
	"mercadomio-backend/services"
)

func connectTestDB(t *testing.T) *mongo.Database {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	client, err := mongo.Connect(ctx, options.Client().ApplyURI("mongodb://localhost:27017"))
	if err != nil {
		t.Fatalf("failed to connect to mongo: %v", err)
	}
	db := client.Database("mercadomio_test")
	t.Cleanup(func() {
		dropCtx, dropCancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer dropCancel()
		for _, name := range []string{"price_sets", "price_schedules", "price_history"} {
			_ = db.Collection(name).Drop(dropCtx)
		}
		_ = client.Disconnect(dropCtx)
	})
	return db
}

func TestPricingResolvePricesIntegration(t *testing.T) {
	db := connectTestDB(t)
	ctx := context.Background()

	pricingService := services.NewPricingService(db, nil)

	product1 := &services.Product{
		ID:        primitive.NewObjectID(),
		Name:      "Rope Test Product",
		BasePrice: 100,
	}
	product2 := &services.Product{
		ID:        primitive.NewObjectID(),
		Name:      "Rope Test Product 2",
		BasePrice: 200,
	}

	set, err := pricingService.CreatePriceSet(ctx, &models.PriceSet{
		Name:             "SAVE10",
		Priority:         1,
		StopFurtherRules: true,
		Active:           true,
		Conditions:       models.PriceConditions{CouponCode: "SAVE10"},
		Rules: []models.PriceRule{
			{Kind: models.RuleKindPercentage, Amount: 10, Scope: models.RuleScopeAll, Priority: 1},
		},
	})
	if err != nil {
		t.Fatalf("failed to create price set: %v", err)
	}
	if set.ID.IsZero() {
		t.Fatal("price set ID is zero")
	}

	now := time.Now()
	schedule, err := pricingService.CreatePriceSchedule(ctx, &models.PriceSchedule{
		Name:          "Inflation +5%",
		Scope:         models.ScheduleScopeGlobal,
		Mode:          models.ScheduleModePercentage,
		Value:         5,
		Priority:      1,
		Active:        true,
		EffectiveFrom: now.Add(-time.Hour),
		EffectiveTo:   pointerTime(now.Add(time.Hour)),
	})
	if err != nil {
		t.Fatalf("failed to create price schedule: %v", err)
	}
	if schedule.ID.IsZero() {
		t.Fatal("price schedule ID is zero")
	}

	result, err := pricingService.ResolvePrices(ctx, []services.PriceInput{
		{Product: product1, Quantity: 2},
		{Product: product2, Quantity: 1},
	}, services.PricingContext{
		Date:       now,
		CouponCode: "SAVE10",
	})
	if err != nil {
		t.Fatalf("ResolvePrices failed: %v", err)
	}

	// Schedule: base * 1.05. Subtotal BEFORE sets = 100*2 + 200 = 400.
	// Product prices after schedule: 105 and 210.
	// Set SAVE10: 10% off each line. Line1: 105 -> 94.5 unt*2 = 189. Line2: 210 -> 189.
	expectedSubtotal := 400.0
	expectedTotal := 189.0 + 189.0
	if absDiffF(result.Subtotal, expectedSubtotal) > 1e-6 {
		t.Errorf("Subtotal = %v, want %v", result.Subtotal, expectedSubtotal)
	}
	if absDiffF(result.Total, expectedTotal) > 1e-6 {
		t.Errorf("Total = %v, want %v", result.Total, expectedTotal)
	}
	if absDiffF(result.Discount, expectedSubtotal-expectedTotal) > 1e-6 {
		t.Errorf("Discount = %v, want %v", result.Discount, expectedSubtotal-expectedTotal)
	}
	if len(result.AppliedSets) != 1 {
		t.Errorf("AppliedSets = %d, want 1", len(result.AppliedSets))
	}
	if len(result.Lines) != 2 {
		t.Errorf("Lines = %d, want 2", len(result.Lines))
	}
	if len(result.AppliedScheduleNames) != 1 || result.AppliedScheduleNames[0] != "Inflation +5%" {
		t.Errorf("AppliedScheduleNames = %v, want [Inflation +5%%]", result.AppliedScheduleNames)
	}
}

func TestPricingNoCouponNoSets(t *testing.T) {
	db := connectTestDB(t)
	ctx := context.Background()
	pricingService := services.NewPricingService(db, nil)

	result, err := pricingService.ResolvePrices(ctx, []services.PriceInput{
		{Product: &services.Product{ID: primitive.NewObjectID(), BasePrice: 100}, Quantity: 1},
	}, services.PricingContext{Date: time.Now()})
	if err != nil {
		t.Fatalf("ResolvePrices failed: %v", err)
	}
	if absDiffF(result.Subtotal, 100) > 1e-6 || absDiffF(result.Total, 100) > 1e-6 {
		t.Errorf("expected no-op resolve, got subtotal=%v total=%v", result.Subtotal, result.Total)
	}
}

func pointerTime(t time.Time) *time.Time {
	return &t
}

func absDiffF(a, b float64) float64 {
	if a > b {
		return a - b
	}
	return b - a
}
