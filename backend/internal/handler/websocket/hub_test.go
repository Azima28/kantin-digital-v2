package websocket

import (
	"encoding/json"
	"testing"
	"time"
)

func TestHubBroadcast(t *testing.T) {
	hub := NewHub()
	go hub.Run()

	// Ensure broadcasting to empty room doesn't panic
	hub.BroadcastToRoom("canteen:01", "order:new", map[string]string{"id": "order-123"})
	hub.BroadcastToRoom("all", "ping", "pong")

	time.Sleep(10 * time.Millisecond)
}

func TestHubRoomIsolation(t *testing.T) {
	hub := NewHub()
	go hub.Run()

	clientOrder := &Client{
		hub:  hub,
		send: make(chan []byte, 10),
		Room: "order:123",
		User: "student-1",
	}

	clientAll := &Client{
		hub:  hub,
		send: make(chan []byte, 10),
		Room: "all",
		User: "guest-1",
	}

	clientOther := &Client{
		hub:  hub,
		send: make(chan []byte, 10),
		Room: "order:999",
		User: "student-2",
	}

	hub.register <- clientOrder
	hub.register <- clientAll
	hub.register <- clientOther

	time.Sleep(20 * time.Millisecond)

	// Broadcast strictly to order:123
	hub.BroadcastToRoom("order:123", "order:message", map[string]string{
		"text": "pesan rahasia",
	})

	time.Sleep(20 * time.Millisecond)

	// clientOrder should receive the message
	select {
	case msg := <-clientOrder.send:
		var payload EventPayload
		if err := json.Unmarshal(msg, &payload); err != nil {
			t.Fatalf("Failed to unmarshal payload: %v", err)
		}
		if payload.Event != "order:message" {
			t.Errorf("Expected event order:message, got %s", payload.Event)
		}
	default:
		t.Error("Expected clientOrder to receive message, but channel was empty")
	}

	// clientAll should NOT receive private order:123 messages
	select {
	case msg := <-clientAll.send:
		t.Errorf("Security Leak: clientAll in room 'all' received private room message: %s", string(msg))
	default:
		// Passed: channel is empty
	}

	// clientOther should NOT receive order:123 messages
	select {
	case msg := <-clientOther.send:
		t.Errorf("Security Leak: clientOther in room 'order:999' received private room message: %s", string(msg))
	default:
		// Passed: channel is empty
	}
}
