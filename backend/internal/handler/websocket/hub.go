package websocket

import (
	"encoding/json"
	"sync"
	"time"
)

type EventPayload struct {
	Event string      `json:"event"`
	Data  interface{} `json:"data"`
	Room  string      `json:"room,omitempty"`
}

type Hub struct {
	clients      map[*Client]bool
	rooms        map[string]map[*Client]bool
	userClients  map[string]map[*Client]bool
	userLastSeen map[string]time.Time
	broadcast    chan []byte
	register     chan *Client
	unregister   chan *Client
	mu           sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		clients:      make(map[*Client]bool),
		rooms:        make(map[string]map[*Client]bool),
		userClients:  make(map[string]map[*Client]bool),
		userLastSeen: make(map[string]time.Time),
		broadcast:    make(chan []byte, 256),
		register:     make(chan *Client),
		unregister:   make(chan *Client),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			if client.Room != "" {
				if _, ok := h.rooms[client.Room]; !ok {
					h.rooms[client.Room] = make(map[*Client]bool)
				}
				h.rooms[client.Room][client] = true
			}

			var justCameOnline bool
			if client.User != "" && client.User != "guest" {
				if _, ok := h.userClients[client.User]; !ok {
					h.userClients[client.User] = make(map[*Client]bool)
				}
				if len(h.userClients[client.User]) == 0 {
					justCameOnline = true
				}
				h.userClients[client.User][client] = true
				h.userLastSeen[client.User] = time.Now()
			}
			h.mu.Unlock()

			if justCameOnline {
				h.broadcastUserPresence(client.User, "online")
			}

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
			if client.Room != "" {
				if roomClients, ok := h.rooms[client.Room]; ok {
					delete(roomClients, client)
					if len(roomClients) == 0 {
						delete(h.rooms, client.Room)
					}
				}
			}

			var justWentOffline bool
			if client.User != "" && client.User != "guest" {
				if userClients, ok := h.userClients[client.User]; ok {
					delete(userClients, client)
					if len(userClients) == 0 {
						delete(h.userClients, client.User)
						h.userLastSeen[client.User] = time.Now()
						justWentOffline = true
					}
				}
			}
			h.mu.Unlock()

			if justWentOffline {
				h.broadcastUserPresence(client.User, "offline")
			}

		case message := <-h.broadcast:
			h.mu.RLock()
			for client := range h.clients {
				select {
				case client.send <- message:
				default:
					close(client.send)
					delete(h.clients, client)
				}
			}
			h.mu.RUnlock()
		}
	}
}

func (h *Hub) broadcastUserPresence(userID, status string) {
	payload := map[string]interface{}{
		"user_id":   userID,
		"status":    status,
		"timestamp": time.Now().Unix(),
	}
	h.BroadcastToRoom("all", "user:presence", payload)
}

// IsUserOnline returns true if the user has an active WebSocket connection
// on the web or had activity within the last 60 seconds.
func (h *Hub) IsUserOnline(userID string) bool {
	if userID == "" || userID == "guest" {
		return false
	}
	h.mu.RLock()
	defer h.mu.RUnlock()

	if clients, ok := h.userClients[userID]; ok && len(clients) > 0 {
		return true
	}
	if lastSeen, ok := h.userLastSeen[userID]; ok {
		if time.Since(lastSeen) < 60*time.Second {
			return true
		}
	}
	return false
}

// TouchUserActivity updates the last active timestamp for a user.
func (h *Hub) TouchUserActivity(userID string) {
	if userID == "" || userID == "guest" {
		return
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	h.userLastSeen[userID] = time.Now()
}

// GetOnlineUsers returns a list of user IDs currently connected on the web.
func (h *Hub) GetOnlineUsers() []string {
	h.mu.RLock()
	defer h.mu.RUnlock()
	users := make([]string, 0, len(h.userClients))
	for u, clients := range h.userClients {
		if len(clients) > 0 {
			users = append(users, u)
		}
	}
	return users
}

// BroadcastToRoom sends a message strictly to clients in the specified room without leaking to other rooms
func (h *Hub) BroadcastToRoom(room, event string, data interface{}) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	payload := EventPayload{
		Event: event,
		Data:  data,
		Room:  room,
	}

	bytes, err := json.Marshal(payload)
	if err != nil {
		return
	}

	// 1. If a specific private or scoped room is targeted (not "all" and not empty),
	// send ONLY to authorized clients registered in that exact room.
	if room != "" && room != "all" {
		if roomClients, ok := h.rooms[room]; ok {
			for client := range roomClients {
				select {
				case client.send <- bytes:
				default:
				}
			}
		}
		return
	}

	// 2. If room == "all" or room == "", broadcast only to clients in "all" or general pool
	sent := make(map[*Client]bool)
	if allClients, ok := h.rooms["all"]; ok {
		for client := range allClients {
			select {
			case client.send <- bytes:
				sent[client] = true
			default:
			}
		}
	}

	if room == "" {
		for client := range h.clients {
			if !sent[client] {
				select {
				case client.send <- bytes:
					sent[client] = true
				default:
				}
			}
		}
	}
}
