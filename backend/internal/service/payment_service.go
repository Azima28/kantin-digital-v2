package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/hasher"
	"kantin-backend/internal/repository/postgres"
)

type PaymentService struct {
	txRepo      *postgres.TransactionRepo
	userRepo    *postgres.UserRepo
	auditRepo   *postgres.AuditRepo
	productRepo *postgres.ProductRepo
	shiftRepo   *postgres.ShiftRepo
}

func NewPaymentService(txRepo *postgres.TransactionRepo, userRepo *postgres.UserRepo, auditRepo *postgres.AuditRepo, productRepo *postgres.ProductRepo, shiftRepo *postgres.ShiftRepo) *PaymentService {
	return &PaymentService{
		txRepo:      txRepo,
		userRepo:    userRepo,
		auditRepo:   auditRepo,
		productRepo: productRepo,
		shiftRepo:   shiftRepo,
	}
}

func (s *PaymentService) GetStudentByRFID(ctx context.Context, rfidUID string) (*domain.Student, error) {
	return s.userRepo.FindStudentByRFID(ctx, rfidUID)
}

func (s *PaymentService) GetStudentByNISN(ctx context.Context, nisn string) (*domain.Student, error) {
	return s.userRepo.FindStudentByNISN(ctx, nisn)
}

func (s *PaymentService) SearchStudents(ctx context.Context, search string) ([]domain.Student, error) {
	return s.userRepo.SearchStudents(ctx, search)
}

func (s *PaymentService) GetStudentDetail(ctx context.Context, studentID string) (*domain.Student, error) {
	return s.userRepo.GetStudentDetail(ctx, studentID)
}

func (s *PaymentService) ProcessPurchase(ctx context.Context, params postgres.CheckoutParams) (*domain.Transaction, error) {
	if params.TotalAmount <= 0 {
		return nil, errors.New("total tagihan harus lebih dari 0")
	}
	return s.txRepo.ProcessPurchase(ctx, params)
}

func (s *PaymentService) ProcessTopup(ctx context.Context, studentID, officerID string, amount int) (*domain.Transaction, error) {
	if amount < 10000 {
		return nil, errors.New("nominal top-up minimal Rp 10.000")
	}
	if amount > 2000000 {
		return nil, errors.New("nominal top-up maksimal Rp 2.000.000 per transaksi")
	}
	return s.txRepo.ProcessTopup(ctx, studentID, officerID, amount)
}

// RequestTopup queues a student's own top-up request without crediting anything.
// Use this for self-service top-up; ProcessTopup is reserved for a finance
// officer who has actually collected the money.
func (s *PaymentService) RequestTopup(ctx context.Context, studentID string, amount int) (*domain.Transaction, error) {
	if amount < 10000 {
		return nil, errors.New("nominal top-up minimal Rp 10.000")
	}
	if amount > 2000000 {
		return nil, errors.New("nominal top-up maksimal Rp 2.000.000 per transaksi")
	}
	return s.txRepo.CreateTopupRequest(ctx, studentID, amount)
}


func (s *PaymentService) ProcessMerchantWithdrawal(ctx context.Context, operatorID, actorID string, amount int, notes, method string) (*domain.Transaction, error) {
	if amount <= 0 {
		return nil, errors.New("nominal penarikan harus lebih dari 0")
	}
	return s.txRepo.ProcessMerchantWithdrawal(ctx, operatorID, actorID, amount, notes, method)
}


func (s *PaymentService) GetFinanceSummary(ctx context.Context) (*postgres.FinanceSummary, error) {
	return s.txRepo.GetFinanceDashboardSummary(ctx)
}

func (s *PaymentService) GetAdminSummary(ctx context.Context) (*postgres.AdminSummary, error) {
	return s.txRepo.GetAdminDashboardSummary(ctx)
}

func (s *PaymentService) GetFinanceReport(ctx context.Context, startDate, endDate time.Time) (*postgres.FinanceReport, error) {
	return s.txRepo.GetFinanceReport(ctx, startDate, endDate)
}

func (s *PaymentService) ListAllStudents(ctx context.Context) ([]domain.Student, error) {
	return s.userRepo.ListAllStudents(ctx)
}

// GetUserByID loads a profile so callers can check who they are about to touch
// before touching it (target role, current field values) instead of trusting the
// request body.
func (s *PaymentService) GetUserByID(ctx context.Context, id string) (*domain.UserProfile, error) {
	if id == "" {
		return nil, errors.New("user ID wajib disertakan")
	}
	user, err := s.userRepo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("pengguna tidak ditemukan")
	}
	return user, nil
}

// LogAudit writes one entry to the audit trail. Empty strings become NULL so the
// caller does not have to juggle pointers at every call site.
func (s *PaymentService) LogAudit(ctx context.Context, actorID, actionType, description, targetID, oldValue, newValue, ipAddress string) error {
	if s.auditRepo == nil {
		return errors.New("audit repository not initialized")
	}
	optional := func(v string) *string {
		if v == "" {
			return nil
		}
		return &v
	}
	entry := &domain.AuditLog{
		ActorID:    optional(actorID),
		ActionType: actionType,
		// The repo maps Description -> audit_logs.entity_name, which is NOT NULL.
		Description: description,
		TargetID:    optional(targetID),
		OldValue:    optional(oldValue),
		NewValue:    optional(newValue),
		IPAddress:   optional(ipAddress),
	}
	return s.auditRepo.LogAction(ctx, entry)
}

func (s *PaymentService) ListAllUsers(ctx context.Context, roleFilter string) ([]postgres.EnrichedUserProfile, error) {
	return s.userRepo.ListAllUsers(ctx, roleFilter)
}

// CreateUser creates an account and returns the temporary password it generated,
// or an empty string when the caller supplied one.
//
// It used to fall back to the literal "password123" whenever no password was
// given, which meant every account created that way -- including staff accounts
// -- shared one password that is published in the app's own demo panel. A random
// password is generated instead and handed back exactly once, to be relayed to
// the account holder; it is never written to the audit trail.
func (s *PaymentService) CreateUser(ctx context.Context, user *domain.UserProfile, rawPassword string, canteenName string, rfidUID *string, studentNISN *string, studentClass *string) (string, error) {
	tempPassword := ""
	if rawPassword == "" {
		generated, err := hasher.GenerateTempPassword()
		if err != nil {
			return "", err
		}
		rawPassword = generated
		tempPassword = generated
	} else if len([]rune(rawPassword)) < 6 {
		return "", errors.New("kata sandi minimal 6 karakter")
	}

	hash, err := hasher.HashPassword(rawPassword)
	if err != nil {
		return "", err
	}
	if err := s.userRepo.CreateUserProfile(ctx, user, hash, canteenName, rfidUID, studentNISN, studentClass); err != nil {
		return "", err
	}
	return tempPassword, nil
}

func (s *PaymentService) UpdateUserStatus(ctx context.Context, id string, isActive bool) error {
	return s.userRepo.UpdateUserStatus(ctx, id, isActive)
}

func (s *PaymentService) AdminChangePassword(ctx context.Context, userID string, newPassword string) error {
	hash, err := hasher.HashPassword(newPassword)
	if err != nil {
		return err
	}
	return s.userRepo.UpdatePassword(ctx, userID, hash)
}

func (s *PaymentService) UpdateStudentCardStatus(ctx context.Context, studentID string, rfidUID *string, isActive *bool) error {
	return s.userRepo.UpdateStudentCardStatus(ctx, studentID, rfidUID, isActive)
}

func (s *PaymentService) UpdateUser(ctx context.Context, user *domain.UserProfile) error {
	return s.userRepo.UpdateUserProfile(ctx, user)
}

// Role-scoped fields live in their own tables and are updated separately from the
// profile. There is no cross-table transaction here on purpose: the handler needs
// to be able to tell the admin that the profile saved but the role data did not,
// which is more useful than rolling both back and reporting nothing at all.
func (s *PaymentService) UpdateCanteenOperatorProfile(ctx context.Context, operatorID, canteenName string) error {
	return s.userRepo.UpdateCanteenOperatorProfile(ctx, operatorID, canteenName)
}

func (s *PaymentService) UpdateFinanceOfficerProfile(ctx context.Context, officerID string, assignedSchool, authorityLevel *string) error {
	return s.userRepo.UpdateFinanceOfficerProfile(ctx, officerID, assignedSchool, authorityLevel)
}

func (s *PaymentService) SetParentLinkedStudents(ctx context.Context, parentID string, nisns []string) (int, []string, error) {
	return s.userRepo.SetParentLinkedStudents(ctx, parentID, nisns)
}

func (s *PaymentService) GetCurrentShiftSummary(ctx context.Context, officerID string) (*domain.CurrentShiftSummary, error) {
	if s.shiftRepo == nil {
		return nil, errors.New("shift repository not initialized")
	}
	return s.shiftRepo.GetCurrentShiftSummary(ctx, officerID)
}

func (s *PaymentService) CloseCurrentShift(ctx context.Context, officerID string, actualPhysicalCash int, notes string) (*domain.CashierShift, error) {
	if s.shiftRepo == nil {
		return nil, errors.New("shift repository not initialized")
	}
	return s.shiftRepo.CloseCurrentShift(ctx, postgres.CloseShiftParams{
		OfficerID:          officerID,
		ActualPhysicalCash: actualPhysicalCash,
		Notes:              notes,
	})
}

func (s *PaymentService) ListShifts(ctx context.Context, officerID string, limit, offset int) ([]domain.CashierShift, int, error) {
	if s.shiftRepo == nil {
		return nil, 0, errors.New("shift repository not initialized")
	}
	return s.shiftRepo.ListShifts(ctx, officerID, limit, offset)
}

func (s *PaymentService) VerifyShift(ctx context.Context, shiftID, adminID string) (*domain.CashierShift, error) {
	if s.shiftRepo == nil {
		return nil, errors.New("shift repository not initialized")
	}
	return s.shiftRepo.VerifyShift(ctx, shiftID, adminID)
}

func (s *PaymentService) UpdateStudentFull(ctx context.Context, p postgres.UpdateStudentFullParams) error {
	return s.userRepo.UpdateStudentFull(ctx, p)
}

// DeleteUser removes a profile. Because all eleven child tables reference
// profiles with ON DELETE CASCADE, this is not a "remove the account" operation
// -- it erases that person's transactions, orders, messages and notifications
// too, with no way back. A profile that carries any financial or order history
// is therefore refused here; deactivating it keeps the ledger intact and is what
// the caller is told to do instead. The check lives in the service so it applies
// to every call site, not just the admin HTTP handler.
func (s *PaymentService) DeleteUser(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("user ID wajib disertakan")
	}
	refs, err := s.userRepo.CountUserLedgerRefs(ctx, id)
	if err != nil {
		return err
	}
	if refs > 0 {
		return fmt.Errorf("pengguna tidak dapat dihapus karena masih memiliki %d riwayat transaksi/pesanan; nonaktifkan akun ini agar riwayat keuangan tetap utuh", refs)
	}
	return s.userRepo.DeleteUser(ctx, id)
}

func (s *PaymentService) UpdateStudentSettings(ctx context.Context, studentID string, dailyLimit *int, isActive *bool, waEnabled *bool, parentPhone *string) error {
	return s.userRepo.UpdateStudentSettings(ctx, studentID, dailyLimit, isActive, waEnabled, parentPhone)
}

func (s *PaymentService) GetParentChildren(ctx context.Context, parentID string) ([]domain.Student, error) {
	return s.userRepo.GetParentChildren(ctx, parentID)
}

func (s *PaymentService) GetStudentSpendingStats(ctx context.Context, studentID string) (*postgres.StudentSpendingStats, error) {
	return s.txRepo.GetStudentSpendingStats(ctx, studentID)
}

func (s *PaymentService) ListAllAuditLogs(ctx context.Context, limit int) ([]domain.AuditLog, error) {
	return s.auditRepo.List(ctx, limit)
}

func (s *PaymentService) ListStudentTransactions(ctx context.Context, studentID string, limit int) ([]domain.Transaction, error) {
	return s.txRepo.ListTransactionsByStudent(ctx, studentID, limit)
}

func (s *PaymentService) ListStudentTransactionsPaged(ctx context.Context, studentID, operatorID string, limit, offset int, txType, status, search string) ([]domain.Transaction, int, error) {
	return s.txRepo.ListTransactionsByStudentPaged(ctx, studentID, operatorID, limit, offset, txType, status, search)
}

func (s *PaymentService) ListTransactionsPaged(ctx context.Context, studentID, operatorID string, limit, offset int, txType, status, search string) ([]domain.Transaction, int, error) {
	return s.txRepo.ListTransactionsPaged(ctx, studentID, operatorID, limit, offset, txType, status, search)
}

func (s *PaymentService) ListOperatorTransactions(ctx context.Context, operatorID string, limit int) ([]domain.Transaction, error) {
	return s.txRepo.ListTransactionsByOperator(ctx, operatorID, limit)
}

func (s *PaymentService) ListOperatorActivities(ctx context.Context, operatorID string, limit int) ([]domain.AuditLog, error) {
	return s.auditRepo.ListByOperator(ctx, operatorID, limit)
}

func (s *PaymentService) GetMerchantDetail(ctx context.Context, merchantID string) (map[string]interface{}, error) {
	operator, err := s.userRepo.GetCanteenOperatorDetail(ctx, merchantID)
	if err != nil {
		return nil, err
	}

	products, _ := s.productRepo.ListProducts(ctx, "", merchantID, "")
	txs, _ := s.txRepo.ListTransactionsByOperator(ctx, merchantID, 30)
	dailySales, monthlySales, _ := s.txRepo.GetOperatorSalesStats(ctx, merchantID)

	return map[string]interface{}{
		"profile":                  operator.Profile,
		"operator":                 operator,
		"products":                 products,
		"transactions":             txs,
		"daily_sales_aggregated":   dailySales,
		"monthly_sales_aggregated": monthlySales,
	}, nil
}

func (s *PaymentService) GetParentDetail(ctx context.Context, parentID string) (map[string]interface{}, error) {
	parent, err := s.userRepo.FindByID(ctx, parentID)
	if err != nil {
		return nil, err
	}

	children, _ := s.userRepo.GetParentChildren(ctx, parentID)
	return map[string]interface{}{
		"profile":  parent,
		"children": children,
	}, nil
}

func (s *PaymentService) GetFinanceOfficerDetail(ctx context.Context, officerID string) (map[string]interface{}, error) {
	officer, err := s.userRepo.GetFinanceOfficerDetail(ctx, officerID)
	if err != nil {
		return nil, err
	}

	logs, _ := s.auditRepo.List(ctx, 30)
	return map[string]interface{}{
		"profile": officer.Profile,
		"officer": officer,
		"logs":    logs,
	}, nil
}

func (s *PaymentService) ListFinanceOfficersLedger(ctx context.Context) ([]domain.FinanceOfficerLedgerItem, error) {
	return s.userRepo.ListFinanceOfficersLedger(ctx)
}

func (s *PaymentService) GetFinanceOfficerLedgerDetail(ctx context.Context, officerID string) (*domain.FinanceOfficerLedgerDetail, error) {
	return s.userRepo.GetFinanceOfficerLedgerDetail(ctx, officerID)
}

