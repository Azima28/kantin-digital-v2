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
	txRepo    *postgres.TransactionRepo
	userRepo  *postgres.UserRepo
	auditRepo *postgres.AuditRepo
}

func NewPaymentService(txRepo *postgres.TransactionRepo, userRepo *postgres.UserRepo, auditRepo *postgres.AuditRepo) *PaymentService {
	return &PaymentService{
		txRepo:    txRepo,
		userRepo:  userRepo,
		auditRepo: auditRepo,
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
	if amount <= 0 {
		return nil, errors.New("nominal top-up harus lebih dari 0")
	}
	return s.txRepo.ProcessTopup(ctx, studentID, officerID, amount)
}

func (s *PaymentService) ProcessCorrection(ctx context.Context, studentID, officerID string, amount int, reason string) (*domain.Transaction, error) {
	if amount == 0 {
		return nil, errors.New("nominal koreksi tidak boleh 0")
	}
	return s.txRepo.ProcessCorrection(ctx, studentID, officerID, amount, reason)
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

func (s *PaymentService) ListAllUsers(ctx context.Context, roleFilter string) ([]domain.UserProfile, error) {
	return s.userRepo.ListAllUsers(ctx, roleFilter)
}

func (s *PaymentService) CreateUser(ctx context.Context, user *domain.UserProfile, rawPassword string, canteenName string, rfidUID *string) error {
	if rawPassword == "" {
		rawPassword = "password123"
	}
	hash, err := hasher.HashPassword(rawPassword)
	if err != nil {
		return err
	}
	return s.userRepo.CreateUserProfile(ctx, user, hash, canteenName, rfidUID)
}

func (s *PaymentService) UpdateUser(ctx context.Context, user *domain.UserProfile) error {
	return s.userRepo.UpdateUserProfile(ctx, user)
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

func (s *PaymentService) ListStudentTransactionsPaged(ctx context.Context, studentID string, limit, offset int, txType, status, search string) ([]domain.Transaction, int, error) {
	return s.txRepo.ListTransactionsByStudentPaged(ctx, studentID, limit, offset, txType, status, search)
}

func (s *PaymentService) ListTransactionsPaged(ctx context.Context, studentID string, limit, offset int, txType, status, search string) ([]domain.Transaction, int, error) {
	return s.txRepo.ListTransactionsPaged(ctx, studentID, limit, offset, txType, status, search)
}

func (s *PaymentService) ListOperatorTransactions(ctx context.Context, operatorID string, limit int) ([]domain.Transaction, error) {
	return s.txRepo.ListTransactionsByOperator(ctx, operatorID, limit)
}

func (s *PaymentService) ListOperatorActivities(ctx context.Context, operatorID string, limit int) ([]domain.AuditLog, error) {
	return s.auditRepo.ListByOperator(ctx, operatorID, limit)
}
