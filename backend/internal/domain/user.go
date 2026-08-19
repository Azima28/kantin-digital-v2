package domain

import (
	"time"
)

type Role string

const (
	RoleStudent         Role = "student"
	RolePetugasKantin   Role = "petugas_kantin"
	RolePetugasKeuangan Role = "petugas_keuangan"
	RoleParent          Role = "parent"
	RoleSuperAdmin      Role = "super_admin"
	RoleAdmin           Role = "admin"
)

type UserProfile struct {
	ID          string     `json:"id"`
	Email       *string    `json:"email,omitempty"`
	FullName    string     `json:"full_name"`
	Role        Role       `json:"role"`
	Password    *string    `json:"-"`
	Username    *string    `json:"username,omitempty"`
	NISN        *string    `json:"nisn,omitempty"`
	PhoneNumber *string    `json:"phone_number,omitempty"`
	IsActive    bool       `json:"is_active"`
	Relation    *string    `json:"relation,omitempty"`
	AvatarURL   *string    `json:"avatar_url,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
}

type Student struct {
	ID                     string       `json:"id"`
	Balance                int          `json:"balance"`
	RfidUID                *string      `json:"rfid_uid,omitempty"`
	IsActive               bool         `json:"is_active"`
	DailyLimit             int          `json:"daily_limit"`
	WANotificationsEnabled bool         `json:"wa_notifications_enabled"`
	ParentPhone            *string      `json:"parent_phone,omitempty"`
	Class                  string       `json:"class"`
	Rombel                 string       `json:"rombel"`
	ClassID                *string      `json:"class_id,omitempty"`
	RombelID               *string      `json:"rombel_id,omitempty"`
	Profile                *UserProfile `json:"profile,omitempty"`
}

type CanteenOperator struct {
	ID                string       `json:"id"`
	CanteenName       string       `json:"canteen_name"`
	BalanceEarned     int          `json:"balance_earned"`
	IsDeliveryEnabled bool         `json:"is_delivery_enabled"`
	DeliveryFee       int          `json:"delivery_fee"`
	Rating            float64      `json:"rating"`
	TotalReviews      int          `json:"total_reviews"`
	Profile           *UserProfile `json:"profile,omitempty"`
}

type FinanceOfficer struct {
	ID                string       `json:"id"`
	TotalManagedFunds int64        `json:"total_managed_funds"`
	Profile           *UserProfile `json:"profile,omitempty"`
}

type ParentStudent struct {
	ID        string       `json:"id"`
	ParentID  string       `json:"parent_id"`
	StudentID string       `json:"student_id"`
	CreatedAt time.Time    `json:"created_at"`
	Student   *Student     `json:"student,omitempty"`
	Parent    *UserProfile `json:"parent,omitempty"`
}

type UserSession struct {
	ID        string    `json:"id"`
	ProfileID string    `json:"profile_id"`
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
}

type AcademicMajor struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	Code string `json:"code"`
}

type AcademicStructure struct {
	SchoolType  string          `json:"school_type"`
	SchoolName  string          `json:"school_name"`
	HasMajors   bool            `json:"has_majors"`
	Majors      []AcademicMajor `json:"majors"`
	GradeLevels []string        `json:"grade_levels"`
	Rombels     []string        `json:"rombels"`
	UpdatedAt   time.Time       `json:"updated_at"`
}

type FinanceOfficerLedgerItem struct {
	ID                string       `json:"id"`
	FullName          string       `json:"full_name"`
	Email             *string      `json:"email,omitempty"`
	Username          *string      `json:"username,omitempty"`
	PhoneNumber       *string      `json:"phone_number,omitempty"`
	IsActive          bool         `json:"is_active"`
	AvatarURL         *string      `json:"avatar_url,omitempty"`
	AssignedSchool    string       `json:"assigned_school"`
	AuthorityLevel    string       `json:"authority_level"`
	TotalCashInflow   int          `json:"total_cash_inflow"`
	TotalCashOutflow  int          `json:"total_cash_outflow"`
	NetCashHandled    int          `json:"net_cash_handled"`
	TotalTransactions int          `json:"total_transactions"`
	TodayCashInflow   int          `json:"today_cash_inflow"`
	TodayCashOutflow  int          `json:"today_cash_outflow"`
	TodayNetCash      int          `json:"today_net_cash"`
	TodayTxCount      int          `json:"today_tx_count"`
	CreatedAt         time.Time    `json:"created_at"`
}

type OfficerJournalEntry struct {
	ID            string    `json:"id"`
	TransactionID *string   `json:"transaction_id,omitempty"`
	Type          string    `json:"type"`     // TOPUP, WITHDRAWAL
	Category      string    `json:"category"` // INFLOW, OUTFLOW
	Amount        int       `json:"amount"`
	TargetName    string    `json:"target_name"`
	TargetRole    string    `json:"target_role"`
	TargetID      string    `json:"target_id"`
	Notes         string    `json:"notes"`
	Method        string    `json:"method"`
	CreatedAt     time.Time `json:"created_at"`
}

type FinanceOfficerLedgerDetail struct {
	Officer        FinanceOfficerLedgerItem `json:"officer"`
	RecentJournals []OfficerJournalEntry    `json:"recent_journals"`
	WeeklyInflow   []int                    `json:"weekly_inflow"`
	WeeklyOutflow  []int                    `json:"weekly_outflow"`
}

