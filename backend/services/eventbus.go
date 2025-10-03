package services

import (
	"context"
	"fmt"
	"strings"
	"sync"
)

// EventHandler defines a function that handles domain events
type EventHandler func(ctx context.Context, event DomainEvent) error

// EventBus defines the interface for publishing and subscribing to domain events
type EventBus interface {
	Publish(ctx context.Context, event DomainEvent) error
	Subscribe(eventPattern string, handler EventHandler)
	Unsubscribe(eventPattern string, handler EventHandler)
}

// InMemoryEventBus is a simple in-memory implementation of EventBus
type InMemoryEventBus struct {
	handlers map[string][]EventHandler
	mu       sync.RWMutex
}

// NewInMemoryEventBus creates a new in-memory event bus
func NewInMemoryEventBus() *InMemoryEventBus {
	return &InMemoryEventBus{
		handlers: make(map[string][]EventHandler),
	}
}

// Subscribe registers an event handler for a specific event pattern
// Patterns support wildcards: "cart.*" matches all cart events, "*" matches all events
func (bus *InMemoryEventBus) Subscribe(eventPattern string, handler EventHandler) {
	bus.mu.Lock()
	defer bus.mu.Unlock()
	bus.handlers[eventPattern] = append(bus.handlers[eventPattern], handler)
}

// Unsubscribe removes an event handler (not implemented for simplicity)
func (bus *InMemoryEventBus) Unsubscribe(eventPattern string, handler EventHandler) {
	// Implementation would require comparing function pointers, which is complex
	// For now, we'll keep this simple and not implement unsubscribe
}

// Publish publishes an event to all matching subscribers
func (bus *InMemoryEventBus) Publish(ctx context.Context, event DomainEvent) error {
	bus.mu.RLock()
	var matchingHandlers []EventHandler
	// Find all handlers that match the event type
	eventType := event.EventType()
	for pattern, handlers := range bus.handlers {
		if bus.matchesPattern(eventType, pattern) {
			matchingHandlers = append(matchingHandlers, handlers...)
		}
	}
	bus.mu.RUnlock()

	// Execute handlers asynchronously to not block business logic
	// Each handler runs in its own goroutine for maximum parallelism
	for _, handler := range matchingHandlers {
		go func(h EventHandler) {
			// Use background context to prevent cancellation from affecting event processing
			if err := h(context.Background(), event); err != nil {
				// Log error but don't fail the publish operation
				// TODO: Add proper structured logging
				fmt.Printf("Event handler error for %s: %v\n", eventType, err)
			}
		}(handler)
	}

	return nil
}

// matchesPattern checks if an event type matches a subscription pattern
func (bus *InMemoryEventBus) matchesPattern(eventType, pattern string) bool {
	// Exact match
	if eventType == pattern {
		return true
	}

	// Wildcard match
	if pattern == "*" {
		return true
	}

	// Prefix wildcard match (e.g., "cart.*" matches "cart.item.added")
	if strings.HasSuffix(pattern, "*") {
		prefix := strings.TrimSuffix(pattern, "*")
		return strings.HasPrefix(eventType, prefix)
	}

	return false
}

// AsyncEventBus wraps the InMemoryEventBus to provide additional async guarantees
type AsyncEventBus struct {
	*InMemoryEventBus
	bufferSize int
	eventChan  chan eventWithContext
	done       chan struct{}
}

type eventWithContext struct {
	ctx   context.Context
	event DomainEvent
}

// NewAsyncEventBus creates an event bus that processes events asynchronously through a channel
func NewAsyncEventBus(bufferSize int) *AsyncEventBus {
	bus := &AsyncEventBus{
		InMemoryEventBus: NewInMemoryEventBus(),
		bufferSize:       bufferSize,
		eventChan:        make(chan eventWithContext, bufferSize),
		done:             make(chan struct{}),
	}

	// Start the event processing goroutine
	go bus.processEvents()

	return bus
}

// Publish adds the event to the processing queue
func (bus *AsyncEventBus) Publish(ctx context.Context, event DomainEvent) error {
	select {
	case bus.eventChan <- eventWithContext{ctx: ctx, event: event}:
		return nil
	default:
		// Channel is full, fall back to synchronous processing
		return bus.InMemoryEventBus.Publish(ctx, event)
	}
}

// processEvents processes events from the channel
func (bus *AsyncEventBus) processEvents() {
	for {
		select {
		case eventCtx := <-bus.eventChan:
			bus.InMemoryEventBus.Publish(eventCtx.ctx, eventCtx.event)
		case <-bus.done:
			return
		}
	}
}

// Close shuts down the async event bus
func (bus *AsyncEventBus) Close() {
	close(bus.done)
	close(bus.eventChan)
}

// EventBusMetrics provides metrics about event bus usage
type EventBusMetrics struct {
	TotalEvents    int64
	EventsByType   map[string]int64
	HandlerErrors  int64
	ActiveHandlers int
}

// MetricsEventBus wraps an EventBus to provide metrics
type MetricsEventBus struct {
	EventBus
	metrics EventBusMetrics
	mu      sync.RWMutex
}

// NewMetricsEventBus wraps an existing event bus with metrics collection
func NewMetricsEventBus(eventBus EventBus) *MetricsEventBus {
	return &MetricsEventBus{
		EventBus: eventBus,
		metrics: EventBusMetrics{
			EventsByType: make(map[string]int64),
		},
	}
}

// Publish publishes an event and updates metrics
func (bus *MetricsEventBus) Publish(ctx context.Context, event DomainEvent) error {
	bus.mu.Lock()
	bus.metrics.TotalEvents++
	bus.metrics.EventsByType[event.EventType()]++
	bus.mu.Unlock()

	return bus.EventBus.Publish(ctx, event)
}

// GetMetrics returns a copy of the current metrics
func (bus *MetricsEventBus) GetMetrics() EventBusMetrics {
	bus.mu.RLock()
	defer bus.mu.RUnlock()

	// Create a copy to avoid race conditions
	metrics := EventBusMetrics{
		TotalEvents:    bus.metrics.TotalEvents,
		HandlerErrors:  bus.metrics.HandlerErrors,
		ActiveHandlers: bus.metrics.ActiveHandlers,
		EventsByType:   make(map[string]int64),
	}

	for k, v := range bus.metrics.EventsByType {
		metrics.EventsByType[k] = v
	}

	return metrics
}
