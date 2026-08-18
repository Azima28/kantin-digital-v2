package service

import (
	"context"

	"kantin-backend/internal/domain"
	"kantin-backend/internal/repository/postgres"
)

type CatalogService struct {
	productRepo *postgres.ProductRepo
	userRepo    *postgres.UserRepo
}

func NewCatalogService(productRepo *postgres.ProductRepo, userRepo *postgres.UserRepo) *CatalogService {
	return &CatalogService{
		productRepo: productRepo,
		userRepo:    userRepo,
	}
}

func (s *CatalogService) ListCanteens(ctx context.Context) ([]domain.CanteenOperator, error) {
	return s.userRepo.ListCanteenOperators(ctx)
}

func (s *CatalogService) UpdateDeliverySettings(ctx context.Context, operatorID string, isEnabled bool, fee int) error {
	return s.userRepo.UpdateDeliverySettings(ctx, operatorID, isEnabled, fee)
}

func (s *CatalogService) ListProducts(ctx context.Context, category, canteenID, search string) ([]domain.Product, error) {
	return s.productRepo.ListProducts(ctx, category, canteenID, search)
}

func (s *CatalogService) GetProductByID(ctx context.Context, id string) (*domain.Product, error) {
	return s.productRepo.GetByID(ctx, id)
}

func (s *CatalogService) CreateProduct(ctx context.Context, p *domain.Product) error {
	return s.productRepo.Create(ctx, p)
}

func (s *CatalogService) UpdateProduct(ctx context.Context, p *domain.Product) error {
	return s.productRepo.Update(ctx, p)
}

func (s *CatalogService) UpdateAvailability(ctx context.Context, id, operatorID string, isAvailable bool) error {
	return s.productRepo.UpdateAvailability(ctx, id, operatorID, isAvailable)
}

func (s *CatalogService) DeleteProduct(ctx context.Context, id, operatorID string) error {
	return s.productRepo.Delete(ctx, id, operatorID)
}

func (s *CatalogService) GetAcademicStructure(ctx context.Context) (*domain.AcademicStructure, error) {
	return s.userRepo.GetAcademicStructure(ctx)
}

func (s *CatalogService) SaveAcademicStructure(ctx context.Context, structData *domain.AcademicStructure) error {
	return s.userRepo.SaveAcademicStructure(ctx, structData)
}

func (s *CatalogService) GetGlobalSettings(ctx context.Context) (map[string]interface{}, error) {
	return s.userRepo.GetGlobalSettings(ctx)
}

func (s *CatalogService) SaveGlobalSettings(ctx context.Context, settings map[string]interface{}) error {
	return s.userRepo.SaveGlobalSettings(ctx, settings)
}
