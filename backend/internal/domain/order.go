package domain

import (
	"time"
)

type OrderStatus string

const (
	OrderStatusBaru                    OrderStatus = "Baru"
	OrderStatusSedangDimasak           OrderStatus = "Sedang Dimasak"
	OrderStatusSedangDisiapkan         OrderStatus = "Sedang Disiapkan"
	OrderStatusSiapDiambil             OrderStatus = "Siap Diambil"
	OrderStatusSiapDiantar             OrderStatus = "Siap Diantar"
	OrderStatusSedangDiantar           OrderStatus = "Sedang Diantar"
	OrderStatusSelesai                 OrderStatus = "Selesai"
	OrderStatusDibatalkan              OrderStatus = "Dibatalkan"
	OrderStatusMenungguPembatalan      OrderStatus = "Menunggu Pembatalan"
	OrderStatusMenungguPersetujuanMurid OrderStatus = "Menunggu Persetujuan Murid"
)

// orderStatusTransitions is the authoritative state machine for an order.
//
// Selesai and Dibatalkan are terminal on purpose. Reaching Selesai releases the
// escrow to canteen_operators.balance_earned, and reaching Dibatalkan refunds
// students.balance -- both are one-way money movements with no offsetting debit
// anywhere in the codebase. Without a state machine, "Selesai -> Baru -> Selesai"
// (or the same loop through Dibatalkan) settles the very same order over and
// over, so the transition table is what keeps an order from being paid twice.
//
// Every other edge here mirrors a transition the operator or student UI can
// actually trigger, including the two backwards edges used to resume an order
// after a cancellation request is rejected.
var orderStatusTransitions = map[OrderStatus][]OrderStatus{
	OrderStatusBaru: {
		OrderStatusSedangDimasak, OrderStatusSedangDisiapkan,
		OrderStatusSiapDiambil, OrderStatusSiapDiantar,
		OrderStatusMenungguPembatalan, OrderStatusMenungguPersetujuanMurid,
		OrderStatusDibatalkan,
	},
	OrderStatusSedangDimasak: {
		OrderStatusSedangDisiapkan, OrderStatusSiapDiambil, OrderStatusSiapDiantar,
		OrderStatusSedangDiantar, OrderStatusSelesai, OrderStatusMenungguPembatalan,
		OrderStatusMenungguPersetujuanMurid, OrderStatusDibatalkan,
	},
	OrderStatusSedangDisiapkan: {
		OrderStatusSedangDimasak, OrderStatusSiapDiambil, OrderStatusSiapDiantar,
		OrderStatusSedangDiantar, OrderStatusSelesai, OrderStatusMenungguPembatalan,
		OrderStatusMenungguPersetujuanMurid, OrderStatusDibatalkan,
	},
	OrderStatusSiapDiambil: {
		OrderStatusSedangDisiapkan, OrderStatusSedangDimasak,
		OrderStatusSedangDiantar, OrderStatusSelesai,
		OrderStatusMenungguPembatalan, OrderStatusMenungguPersetujuanMurid,
		OrderStatusDibatalkan,
	},
	OrderStatusSiapDiantar: {
		OrderStatusSedangDisiapkan, OrderStatusSedangDimasak,
		OrderStatusSedangDiantar, OrderStatusSelesai,
		OrderStatusMenungguPembatalan, OrderStatusMenungguPersetujuanMurid,
		OrderStatusDibatalkan,
	},
	OrderStatusSedangDiantar: {
		OrderStatusSedangDisiapkan, OrderStatusSedangDimasak,
		OrderStatusSiapDiambil, OrderStatusSiapDiantar, OrderStatusSelesai,
		OrderStatusMenungguPembatalan, OrderStatusMenungguPersetujuanMurid,
		OrderStatusDibatalkan,
	},
	// Cancellation waiting rooms: either the request is approved (Dibatalkan) or
	// rejected, in which case the order resumes preparation.
	OrderStatusMenungguPembatalan: {
		OrderStatusDibatalkan, OrderStatusSedangDisiapkan, OrderStatusSedangDimasak,
		OrderStatusSiapDiambil, OrderStatusSiapDiantar, OrderStatusSedangDiantar,
	},
	OrderStatusMenungguPersetujuanMurid: {
		OrderStatusDibatalkan, OrderStatusSedangDisiapkan, OrderStatusSedangDimasak,
		OrderStatusSiapDiambil, OrderStatusSiapDiantar, OrderStatusSedangDiantar,
	},
	// Terminal -- settled, immutable.
	OrderStatusSelesai:    {},
	OrderStatusDibatalkan: {},
}

// IsValidOrderStatus reports whether s is a status this system recognises.
func IsValidOrderStatus(s OrderStatus) bool {
	_, ok := orderStatusTransitions[s]
	return ok
}

// IsTerminalOrderStatus reports whether an order in status s has already been
// settled and may no longer change.
func IsTerminalOrderStatus(s OrderStatus) bool {
	return s == OrderStatusSelesai || s == OrderStatusDibatalkan
}

// CanTransitionOrderStatus reports whether an order may move from -> to.
// A no-op (from == to) is always allowed; callers treat it as "nothing to do"
// so a double-tapped button does not surface an error.
func CanTransitionOrderStatus(from, to OrderStatus) bool {
	if from == to {
		return true
	}
	allowed, ok := orderStatusTransitions[from]
	if !ok {
		return false
	}
	for _, candidate := range allowed {
		if candidate == to {
			return true
		}
	}
	return false
}

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
	ID              string    `json:"id"`
	OrderID         string    `json:"order_id"`
	SenderID        string    `json:"sender_id"`
	SenderRole      string    `json:"sender_role"`
	SenderName      string    `json:"sender_name,omitempty"`
	SenderAvatarURL *string   `json:"sender_avatar_url,omitempty"`
	Message         string    `json:"message"`
	IsRead          bool      `json:"is_read"`
	CreatedAt       time.Time `json:"created_at"`
}

type OrderReview struct {
	ID          string    `json:"id"`
	OrderID     string    `json:"order_id"`
	StudentID   string    `json:"student_id"`
	StudentName string    `json:"student_name,omitempty"`
	AvatarURL   *string   `json:"avatar_url,omitempty"`
	OperatorID  *string   `json:"operator_id,omitempty"`
	ProductID   *string   `json:"product_id,omitempty"`
	ProductName *string   `json:"product_name,omitempty"`
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
