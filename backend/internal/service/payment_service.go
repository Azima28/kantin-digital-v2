package service

import (
	"context"
	"errors"

	"kantin-backend/internal/domain"
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

func (s *PaymentService) ListStudentTransactions(ctx context.Context, studentID string, limit int) ([]domain.Transaction, error) {
	return s.txRepo.ListTransactionsByStudent(ctx, studentID, limit)
}

func (s *PaymentService) ListStudentTransactionsPaged(ctx context.Context, studentID string, limit, offset int, txType, status, search string) ([]domain.Transaction, int, error) {
	return s.txRepo.ListTransactionsByStudentPaged(ctx, studentID, limit, offset, txType, status, search)
}

func (s *PaymentService) ListOperatorTransactions(ctx context.Context, operatorID string, limit int) ([]domain.Transaction, error) {
	return s.txRepo.ListTransactionsByOperator(ctx, operatorID, limit)
}

func (s *PaymentService) ListOperatorActivities(ctx context.Context, operatorID string, limit int) ([]domain.AuditLog, error) {
	return s.auditRepo.ListByOperator(ctx, operatorID, limit)
}
