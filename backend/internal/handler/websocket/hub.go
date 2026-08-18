package websocket

import (
	"encoding/json"
	"sync"
)

type EventPayload struct {
	Event string      `json:"event"`
	Data  interface{} `json:"data"`
	Room  string      `json:"room,omitempty"`
}

type Hub struct {
	clients    map[*Client]bool
	rooms      map[string]map[*Client]bool
	broadcast  chan []byte
	register   chan *Client
	unregister chan *Client
	mu         sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		rooms:      make(map[string]map[*Client]bool),
		broadcast:  make(chan []byte, 256),
		register:   make(chan *Client),
		unregister: make(chan *Client),
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
			h.mu.Unlock()

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
			h.mu.Unlock()

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

// BroadcastToRoom sends a message to clients in a specific room and to the global "all" room
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

	if room == "" || room == "all" {
		for client := range h.clients {
			select {
			case client.send <- bytes:
			default:
			}
		}
		return
	}

	// Send only to specific room clients
	if roomClients, ok := h.rooms[room]; ok {
		for client := range roomClients {
			select {
			case client.send <- bytes:
			default:
			}
		}
	}
}
