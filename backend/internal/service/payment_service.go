package service

import (
	"context"
	"errors"
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

func (s *PaymentService) ListAllUsers(ctx context.Context, roleFilter string) ([]postgres.EnrichedUserProfile, error) {
	return s.userRepo.ListAllUsers(ctx, roleFilter)
}

func (s *PaymentService) CreateUser(ctx context.Context, user *domain.UserProfile, rawPassword string, canteenName string, rfidUID *string, studentNISN *string, studentClass *string) error {
	if rawPassword == "" {
		rawPassword = "password123"
	}
	hash, err := hasher.HashPassword(rawPassword)
	if err != nil {
		return err
	}
	return s.userRepo.CreateUserProfile(ctx, user, hash, canteenName, rfidUID, studentNISN, studentClass)
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

func (s *PaymentService) DeleteUser(ctx context.Context, id string) error {
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

