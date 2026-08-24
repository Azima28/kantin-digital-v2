package domain

import (
	"time"
)

type OrderStatus string

const (
	OrderStatusBaru                    OrderStatus = "Baru"
	OrderStatusSedangDimasak           OrderStatus = "Sedang Dimasak"
	OrderStatusSiapDiambil             OrderStatus = "Siap Diambil"
	OrderStatusSiapDiantar             OrderStatus = "Siap Diantar"
	OrderStatusSelesai                 OrderStatus = "Selesai"
	OrderStatusDibatalkan              OrderStatus = "Dibatalkan"
	OrderStatusMenungguPembatalan      OrderStatus = "Menunggu Pembatalan"
	OrderStatusMenungguPersetujuanMurid OrderStatus = "Menunggu Persetujuan Murid"
)

type OrderItem struct {
	ID              string   `json:"id"`
	OrderID         string   `json:"order_id"`
	ProductID       *string  `json:"product_id,omitempty"`
	ProductName     string   `json:"product_name"`
	Quantity        int      `json:"quantity"`
	Price           int      `json:"price"`
	SelectedOptions []string `json:"selected_options"`
	Notes           string   `json:"notes,omitempty"`
	ImageURL        *string  `json:"image_url,omitempty"`
}

type OrderMessage struct {
	ID         string    `json:"id"`
	OrderID    string    `json:"order_id"`
	SenderID   string    `json:"sender_id"`
	SenderRole string    `json:"sender_role"`
	SenderName string    `json:"sender_name,omitempty"`
	Message    string    `json:"message"`
	IsRead     bool      `json:"is_read"`
	CreatedAt  time.Time `json:"created_at"`
}

type OrderReview struct {
	ID          string    `json:"id"`
	OrderID     string    `json:"order_id"`
	StudentID   string    `json:"student_id"`
	StudentName string    `json:"student_name,omitempty"`
	AvatarURL   *string   `json:"avatar_url,omitempty"`
	OperatorID  *string   `json:"operator_id,omitempty"`
	Rating      int       `json:"rating"`
	ReviewText  string    `json:"review_text"`
	Tags        []string  `json:"tags"`
	IsAnonymous bool      `json:"is_anonymous"`
	CreatedAt   time.Time `json:"created_at"`
}

type Order struct {
	ID                  string          `json:"id"`
	StudentID           string          `json:"student_id"`
	StudentName         string          `json:"student_name"`
	OperatorID          *string         `json:"operator_id,omitempty"`
	Status              OrderStatus     `json:"status"`
	DeliveryLocation    *string         `json:"delivery_location,omitempty"`
	TotalAmount         int             `json:"total_amount"`
	CancelRequestReason *string         `json:"cancel_request_reason,omitempty"`
	CreatedAt           time.Time       `json:"created_at"`
	Items               []OrderItem     `json:"items,omitempty"`
	Messages            []OrderMessage  `json:"messages,omitempty"`
	Review              *OrderReview    `json:"review,omitempty"`
	Operator            *CanteenOperator `json:"operator,omitempty"`
}
