package domain

import (
	"time"
)

type Notification struct {
	ID        string    `json:"id"`
	StudentID string    `json:"student_id"`
	Title     string    `json:"title"`
	Message   string    `json:"message"`
	Type      string    `json:"type"`
	IsRead    bool      `json:"is_read"`
	CreatedAt time.Time `json:"created_at"`
}
