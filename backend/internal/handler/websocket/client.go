package websocket

import (
	"log"

	"github.com/gofiber/websocket/v2"
)

type Client struct {
	hub  *Hub
	conn *websocket.Conn
	send chan []byte
	Room string
	User string
}

func (c *Client) ReadPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	for {
		_, _, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}
		// Client messages are processed as heartbeats / pings; mutations go via REST API
	}
}

func (c *Client) WritePump() {
	defer func() {
		c.conn.Close()
	}()

	for {
		message, ok := <-c.send
		if !ok {
			c.conn.WriteMessage(websocket.CloseMessage, []byte{})
			return
		}

		if err := c.conn.WriteMessage(websocket.TextMessage, message); err != nil {
			return
		}
	}
}

func ServeWS(hub *Hub, room, user string) func(*websocket.Conn) {
	return func(c *websocket.Conn) {
		client := &Client{
			hub:  hub,
			conn: c,
			send: make(chan []byte, 256),
			Room: room,
			User: user,
		}
		client.hub.register <- client

		go client.WritePump()
		client.ReadPump()
	}
}
