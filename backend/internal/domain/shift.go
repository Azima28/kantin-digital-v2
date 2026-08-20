package domain

import "time"

type ShiftStatus string

const (
	ShiftStatusActive   ShiftStatus = "active"
	ShiftStatusClosed   ShiftStatus = "closed"
	ShiftStatusVerified ShiftStatus = "verified"
)

type CashierShift struct {
	ID                 string       `json:"id"`
	OfficerID          string       `json:"officer_id"`
	OfficerName        string       `json:"officer_name,omitempty"`
	ShiftNumber        int          `json:"shift_number"`
	StartedAt          time.Time    `json:"started_at"`
	ClosedAt           *time.Time   `json:"closed_at,omitempty"`
	StartingCash       int          `json:"starting_cash"`
	TotalInflow        int          `json:"total_inflow"`
	TotalOutflow       int          `json:"total_outflow"`
	ExpectedCash       int          `json:"expected_cash"`
	ActualPhysicalCash int          `json:"actual_physical_cash"`
	Difference         int          `json:"difference"`
	TopupCount         int          `json:"topup_count"`
	PayoutCount        int          `json:"payout_count"`
	Notes              string       `json:"notes"`
	Status             ShiftStatus  `json:"status"`
	VerifiedBy         *string      `json:"verified_by,omitempty"`
	VerifierName       *string      `json:"verifier_name,omitempty"`
	VerifiedAt         *time.Time   `json:"verified_at,omitempty"`
	CreatedAt          time.Time    `json:"created_at"`
}

type CurrentShiftSummary struct {
	OfficerID     string    `json:"officer_id"`
	OfficerName   string    `json:"officer_name"`
	ShiftNumber   int       `json:"shift_number"`
	StartedAt     time.Time `json:"started_at"`
	TotalInflow   int       `json:"total_inflow"`
	TotalOutflow  int       `json:"total_outflow"`
	ExpectedCash  int       `json:"expected_cash"`
	TopupCount    int       `json:"topup_count"`
	PayoutCount   int       `json:"payout_count"`
	LastClosedAt  *time.Time `json:"last_closed_at,omitempty"`
}
