package services

import (
	"context"
	"sync/atomic"
	"testing"
	"time"
)

func TestInMemoryEventBus_Unsubscribe_RemovesHandler(t *testing.T) {
	bus := NewInMemoryEventBus()
	var called int32
	handler := func(ctx context.Context, e DomainEvent) error {
		atomic.AddInt32(&called, 1)
		return nil
	}

	bus.Subscribe("cart.*", handler)
	bus.Unsubscribe("cart.*", handler)

	if err := bus.Publish(context.Background(), CartItemAdded{CartID: "c1", Timestamp: time.Now()}); err != nil {
		t.Fatalf("publish failed: %v", err)
	}
	// Allow async handlers to run
	time.Sleep(50 * time.Millisecond)
	if atomic.LoadInt32(&called) != 0 {
		t.Fatalf("expected handler not called after unsubscribe, got %d calls", called)
	}
}

func TestInMemoryEventBus_SubscribeReturnsUnsubscribe_PreventsLeak(t *testing.T) {
	bus := NewInMemoryEventBus()
	var called int32
	handler := func(ctx context.Context, e DomainEvent) error {
		atomic.AddInt32(&called, 1)
		return nil
	}

	unsub := bus.Subscribe("cart.*", handler)
	unsub()
	if err := bus.Publish(context.Background(), CartItemAdded{CartID: "c1", Timestamp: time.Now()}); err != nil {
		t.Fatalf("publish failed: %v", err)
	}
	time.Sleep(50 * time.Millisecond)
	if atomic.LoadInt32(&called) != 0 {
		t.Fatalf("expected 0 calls after unsubscribe via returned func, got %d", called)
	}

	// Subscribe again and verify unsub is precise (only removes one).
	var called2 int32
	h2 := func(ctx context.Context, e DomainEvent) error { atomic.AddInt32(&called2, 1); return nil }
	unsub1 := bus.Subscribe("cart.*", handler)
	unsub2 := bus.Subscribe("cart.*", h2)
	unsub1()
	if err := bus.Publish(context.Background(), CartItemAdded{CartID: "c1", Timestamp: time.Now()}); err != nil {
		t.Fatalf("publish failed: %v", err)
	}
	time.Sleep(50 * time.Millisecond)
	if atomic.LoadInt32(&called) != 0 {
		t.Fatalf("expected first handler removed, got %d", called)
	}
	if atomic.LoadInt32(&called2) != 1 {
		t.Fatalf("expected second handler still active, got %d", called2)
	}
	unsub2()
}

func TestInMemoryEventBus_DoubleSubscribe_WithUnsubscribeFuncs(t *testing.T) {
	bus := NewInMemoryEventBus()
	var called int32
	handler := func(ctx context.Context, e DomainEvent) error {
		atomic.AddInt32(&called, 1)
		return nil
	}
	// Two distinct subscriptions with same handler should both fire,
	// but each can be individually removed via its own unsubscribe func.
	unsub1 := bus.Subscribe("cart.*", handler)
	unsub2 := bus.Subscribe("cart.*", handler)

	if err := bus.Publish(context.Background(), CartItemAdded{CartID: "c1", Timestamp: time.Now()}); err != nil {
		t.Fatalf("publish failed: %v", err)
	}
	time.Sleep(50 * time.Millisecond)
	if atomic.LoadInt32(&called) != 2 {
		t.Fatalf("expected 2 calls with two subscriptions, got %d", called)
	}
	// Remove one – should leave exactly one handler.
	atomic.StoreInt32(&called, 0)
	unsub1()
	if err := bus.Publish(context.Background(), CartItemAdded{CartID: "c1", Timestamp: time.Now()}); err != nil {
		t.Fatalf("publish failed: %v", err)
	}
	time.Sleep(50 * time.Millisecond)
	if atomic.LoadInt32(&called) != 1 {
		t.Fatalf("expected 1 call after removing one subscription, got %d", called)
	}
	unsub2()
	atomic.StoreInt32(&called, 0)
	if err := bus.Publish(context.Background(), CartItemAdded{CartID: "c1", Timestamp: time.Now()}); err != nil {
		t.Fatalf("publish failed: %v", err)
	}
	time.Sleep(50 * time.Millisecond)
	if atomic.LoadInt32(&called) != 0 {
		t.Fatalf("expected 0 calls after removing both, got %d", called)
	}
}

func TestAnalyticsService_StartStop_Idempotent(t *testing.T) {
	bus := NewInMemoryEventBus()
	cfg := &CartAnalyticsConfig{TrackItemViews: true, TrackAbandonedCarts: true, TrackConversions: true, TrackSearches: true}
	svc := NewAnalyticsService(nil, cfg, bus)

	// With nil DB, Start will fail on EnsureIndexes and should NOT leak handlers.
	// It must remain idempotent: second Start must not add more handlers.
	_ = svc.Start()
	bus.mu.RLock()
	firstCount := len(bus.handlers["cart.*"]) + len(bus.handlers["product.viewed"]) + len(bus.handlers["search.performed"])
	bus.mu.RUnlock()

	_ = svc.Start()
	bus.mu.RLock()
	secondCount := len(bus.handlers["cart.*"]) + len(bus.handlers["product.viewed"]) + len(bus.handlers["search.performed"])
	bus.mu.RUnlock()

	if secondCount != firstCount {
		t.Fatalf("Start is not idempotent: first %d handlers, after second Start %d handlers (leak)", firstCount, secondCount)
	}
	// firstCount should be 0 because EnsureIndexes failed before subscribing
	if firstCount != 0 {
		t.Fatalf("expected 0 handlers when DB is nil (no subscription on failed Start), got %d", firstCount)
	}

	if err := svc.Stop(); err != nil {
		t.Fatalf("Stop failed: %v", err)
	}
	bus.mu.RLock()
	afterStop := len(bus.handlers["cart.*"]) + len(bus.handlers["product.viewed"]) + len(bus.handlers["search.performed"])
	bus.mu.RUnlock()
	if afterStop != 0 {
		t.Fatalf("Stop did not unsubscribe: expected 0 handlers, got %d", afterStop)
	}

	// Now verify the successful path via direct bus ops: simulate a service
	// that did subscribe (as it would with a real DB) and ensure Stop cleans up.
	bus2 := NewInMemoryEventBus()
	svc2 := NewAnalyticsService(nil, cfg, bus2)
	// Bypass DB check by directly subscribing like Start would on success
	unsubs := []func(){
		bus2.Subscribe("cart.*", svc2.handleCartEvent),
		bus2.Subscribe("product.viewed", svc2.handleProductViewed),
		bus2.Subscribe("search.performed", svc2.handleSearchPerformed),
	}
	svc2.mu.Lock()
	svc2.unsubs = unsubs
	svc2.started = true
	svc2.mu.Unlock()

	bus2.mu.RLock()
	beforeStop := len(bus2.handlers["cart.*"]) + len(bus2.handlers["product.viewed"]) + len(bus2.handlers["search.performed"])
	bus2.mu.RUnlock()
	if beforeStop != 3 {
		t.Fatalf("expected 3 handlers after simulated successful Start, got %d", beforeStop)
	}
	if err := svc2.Stop(); err != nil {
		t.Fatalf("Stop failed: %v", err)
	}
	bus2.mu.RLock()
	afterStop2 := len(bus2.handlers["cart.*"]) + len(bus2.handlers["product.viewed"]) + len(bus2.handlers["search.performed"])
	bus2.mu.RUnlock()
	if afterStop2 != 0 {
		t.Fatalf("Stop did not clean handlers after successful Start: got %d", afterStop2)
	}
	// Second Stop must be safe (idempotent)
	if err := svc2.Stop(); err != nil {
		t.Fatalf("second Stop failed: %v", err)
	}
}
