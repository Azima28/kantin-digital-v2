package domain

import (
	"time"
)

type Product struct {
	ID                  string          `json:"id"`
	OperatorID          string          `json:"operator_id"`
	Name                string          `json:"name"`
	Price               int             `json:"price"`
	Category            string          `json:"category"`
	IsAvailable         bool            `json:"is_available"`
	ImageURL            *string         `json:"image_url,omitempty"`
	CustomizableOptions []string        `json:"customizable_options"`
	CreatedAt           time.Time       `json:"created_at"`
	CanteenName         *string         `json:"canteen_name,omitempty"`
	IsDeliveryEnabled   bool            `json:"is_delivery_enabled"`
	DeliveryFee         int             `json:"delivery_fee"`
	Rating              float64         `json:"rating"`
	TotalReviews        int             `json:"total_reviews"`
	TotalSold           int             `json:"total_sold"`
	Operator            *CanteenOperator `json:"operator,omitempty"`
}

type ProductWithCanteen struct {
	Product     Product         `json:"product"`
	CanteenName string          `json:"canteen_name"`
	Operator    *CanteenOperator `json:"operator,omitempty"`
}
