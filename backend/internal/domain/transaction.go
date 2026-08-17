package domain

import (
	"time"
)

type TransactionType string

const (
	TxTypePurchase   TransactionType = "purchase"
	TxTypeTopup      TransactionType = "topup"
	TxTypeCorrection TransactionType = "correction"
	TxTypeRefund     TransactionType = "refund"
)

type TransactionStatus string

const (
	TxStatusSuccess   TransactionStatus = "success"
	TxStatusPending   TransactionStatus = "pending"
	TxStatusCancelled TransactionStatus = "cancelled"
	TxStatusRefunded  TransactionStatus = "refunded"
)

type TransactionItem struct {
	ID            string   `json:"id"`
	TransactionID string   `json:"transaction_id"`
	ProductID     *string  `json:"product_id,omitempty"`
	ProductName   *string  `json:"product_name,omitempty"`
	Quantity      int      `json:"quantity"`
	UnitPrice     int      `json:"unit_price"`
	CustomNotes   *string  `json:"custom_notes,omitempty"`
	ImageURL      *string  `json:"image_url,omitempty"`
}

type Transaction struct {
	ID             string            `json:"id"`
	StudentID      string            `json:"student_id"`
	OperatorID     string            `json:"operator_id"`
	TotalAmount    int               `json:"total_amount"`
	Type           TransactionType   `json:"type"`
	Status         TransactionStatus `json:"status"`
	PurchaseMethod string            `json:"purchase_method"`
	CreatedAt      time.Time         `json:"created_at"`
	StudentName    *string           `json:"student_name,omitempty"`
	CanteenName    *string           `json:"canteen_name,omitempty"`
	ImageURL       *string           `json:"image_url,omitempty"`
	Items          []TransactionItem `json:"items,omitempty"`
}

type BalanceAdjustment struct {
	ID        string    `json:"id"`
	StudentID string    `json:"student_id"`
	OfficerID string    `json:"officer_id"`
	Amount    int       `json:"amount"`
	Reason    string    `json:"reason"`
	CreatedAt time.Time `json:"created_at"`
}
