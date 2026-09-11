package services

import (
	"testing"

	"mercadomio-backend/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func TestBuildOrderFilter_TodosReturnsNoStatus(t *testing.T) {
	uid := primitive.NewObjectID()
	filter := buildOrderFilter(uid, "Todos")
	if _, hasStatus := filter["status"]; hasStatus {
		t.Fatalf("Todos should not filter by status, got %v", filter)
	}
	if filter["userId"] != uid {
		t.Fatalf("expected userId %v, got %v", uid, filter["userId"])
	}
}

func TestBuildOrderFilter_EnCaminoMapsToPendingPaidShipped(t *testing.T) {
	uid := primitive.NewObjectID()
	filter := buildOrderFilter(uid, "En camino")
	statusVal, ok := filter["status"]
	if !ok {
		t.Fatalf("En camino should filter by status, got %v", filter)
	}
	m, ok := statusVal.(bson.M)
	if !ok {
		t.Fatalf("status should be bson.M with $in, got %T %v", statusVal, statusVal)
	}
	in, ok := m["$in"]
	if !ok {
		t.Fatalf("expected $in, got %v", m)
	}
	statuses, ok := in.([]models.OrderStatus)
	if !ok {
		t.Fatalf("expected []OrderStatus, got %T", in)
	}
	expected := map[models.OrderStatus]bool{
		models.OrderStatusPending: true, models.OrderStatusPaid: true, models.OrderStatusShipped: true,
	}
	if len(statuses) != 3 {
		t.Fatalf("expected 3 statuses, got %v", statuses)
	}
	for _, s := range statuses {
		if !expected[s] {
			t.Fatalf("unexpected status %v", s)
		}
	}
}

func TestBuildOrderFilter_EntregadosAndCancelados(t *testing.T) {
	uid := primitive.NewObjectID()
	for _, tc := range []struct {
		bucket string
		want   models.OrderStatus
	}{
		{"Entregados", models.OrderStatusCompleted},
		{"Cancelados", models.OrderStatusCancelled},
	} {
		filter := buildOrderFilter(uid, tc.bucket)
		m, ok := filter["status"].(bson.M)
		if !ok {
			t.Fatalf("%s: expected status bson.M, got %v", tc.bucket, filter["status"])
		}
		if m["$in"] == nil && m["$eq"] == nil {
			// allow either $in with single or direct equality
		}
		// Normalize to slice
		var got []models.OrderStatus
		if in, ok := m["$in"]; ok {
			got = in.([]models.OrderStatus)
		} else {
			got = []models.OrderStatus{filter["status"].(models.OrderStatus)}
		}
		if len(got) != 1 || got[0] != tc.want {
			t.Fatalf("%s: expected [%v], got %v", tc.bucket, tc.want, got)
		}
	}
}

func TestBuildOrderFilter_UnknownDefaultsToTodos(t *testing.T) {
	uid := primitive.NewObjectID()
	filter := buildOrderFilter(uid, "unknown")
	if _, hasStatus := filter["status"]; hasStatus {
		t.Fatalf("unknown bucket should not filter, got %v", filter)
	}
}
