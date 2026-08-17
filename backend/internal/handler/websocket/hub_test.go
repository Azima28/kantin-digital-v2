package websocket

import (
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
