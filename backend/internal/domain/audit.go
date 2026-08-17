package domain

import (
	"time"
)

type AuditLog struct {
	ID          string    `json:"id"`
	ActorID     *string   `json:"actor_id,omitempty"`
	ActorName   string    `json:"actor_name"`
	ActionType  string    `json:"action_type"`
	Description string    `json:"description"`
	TargetID    *string   `json:"target_id,omitempty"`
	OldValue    *string   `json:"old_value,omitempty"`
	NewValue    *string   `json:"new_value,omitempty"`
	IPAddress   *string   `json:"ip_address,omitempty"`
	UserAgent   *string   `json:"user_agent,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
}

type SystemSetting struct {
	Key         string    `json:"key"`
	Value       string    `json:"value"`
	Description *string   `json:"description,omitempty"`
	UpdatedAt   time.Time `json:"updated_at"`
}
