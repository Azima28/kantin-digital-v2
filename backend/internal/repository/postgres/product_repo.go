package postgres

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/jackc/pgx/v5"
	"kantin-backend/internal/domain"
)

type ProductRepo struct {
	db *DB
}

func NewProductRepo(db *DB) *ProductRepo {
	return &ProductRepo{db: db}
}

func (r *ProductRepo) ListProducts(ctx context.Context, category, canteenID, search string) ([]domain.Product, error) {
	query := `
		SELECT p.id, p.operator_id, p.name, p.price, p.category, p.is_available, p.image_url, p.customizable_options, p.created_at,
		       c.canteen_name, COALESCE(c.is_delivery_enabled, true), COALESCE(c.delivery_fee, 2000),
		       COALESCE(p.rating, 0.0), COALESCE(p.total_reviews, 0),
		       (COALESCE((SELECT SUM(ti.quantity) FROM public.transaction_items ti WHERE ti.product_id = p.id), 0) +
		        COALESCE((SELECT SUM(oi.quantity) FROM public.order_items oi JOIN public.orders o ON o.id = oi.order_id WHERE LOWER(oi.product_name) = LOWER(p.name) AND o.status = 'Selesai'), 0)) AS total_sold
		FROM public.products p
		JOIN public.canteen_operators c ON c.id = p.operator_id
		WHERE ($1 = '' OR LOWER(p.category) = LOWER($1))
		  AND ($2 = '' OR p.operator_id::text = $2)
		  AND ($3 = '' OR LOWER(p.name) LIKE LOWER('%' || $3 || '%'))
		ORDER BY p.name ASC`

	rows, err := r.db.Pool.Query(ctx, query, category, canteenID, search)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Product
	for rows.Next() {
		var p domain.Product
		var optBytes []byte
		err := rows.Scan(
			&p.ID, &p.OperatorID, &p.Name, &p.Price, &p.Category, &p.IsAvailable, &p.ImageURL, &optBytes, &p.CreatedAt,
			&p.CanteenName, &p.IsDeliveryEnabled, &p.DeliveryFee,
			&p.Rating, &p.TotalReviews, &p.TotalSold,
		)
		if err != nil {
			return nil, err
		}
		if len(optBytes) > 0 {
			_ = json.Unmarshal(optBytes, &p.CustomizableOptions)
		}
		list = append(list, p)
	}
	return list, nil
}

func (r *ProductRepo) GetByID(ctx context.Context, id string) (*domain.Product, error) {
	query := `
		SELECT p.id, p.operator_id, p.name, p.price, p.category, p.is_available, p.image_url, p.customizable_options, p.created_at,
		       c.canteen_name, COALESCE(c.is_delivery_enabled, true), COALESCE(c.delivery_fee, 2000),
		       COALESCE(p.rating, 0.0), COALESCE(p.total_reviews, 0),
		       (COALESCE((SELECT SUM(ti.quantity) FROM public.transaction_items ti WHERE ti.product_id = p.id), 0) +
		        COALESCE((SELECT SUM(oi.quantity) FROM public.order_items oi JOIN public.orders o ON o.id = oi.order_id WHERE LOWER(oi.product_name) = LOWER(p.name) AND o.status = 'Selesai'), 0)) AS total_sold
		FROM public.products p
		JOIN public.canteen_operators c ON c.id = p.operator_id
		WHERE p.id = $1`

	row := r.db.Pool.QueryRow(ctx, query, id)
	var p domain.Product
	var optBytes []byte
	err := row.Scan(
		&p.ID, &p.OperatorID, &p.Name, &p.Price, &p.Category, &p.IsAvailable, &p.ImageURL, &optBytes, &p.CreatedAt,
		&p.CanteenName, &p.IsDeliveryEnabled, &p.DeliveryFee,
		&p.Rating, &p.TotalReviews, &p.TotalSold,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("produk tidak ditemukan")
		}
		return nil, err
	}
	if len(optBytes) > 0 {
		_ = json.Unmarshal(optBytes, &p.CustomizableOptions)
	}
	return &p, nil
}

func (r *ProductRepo) Create(ctx context.Context, p *domain.Product) error {
	optJSON, _ := json.Marshal(p.CustomizableOptions)
	query := `
		INSERT INTO public.products (operator_id, name, price, category, is_available, image_url, customizable_options)
		VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb)
		RETURNING id, created_at`

	return r.db.Pool.QueryRow(ctx, query,
		p.OperatorID, p.Name, p.Price, p.Category, p.IsAvailable, p.ImageURL, optJSON,
	).Scan(&p.ID, &p.CreatedAt)
}

func (r *ProductRepo) Update(ctx context.Context, p *domain.Product) error {
	// If partial fields are submitted, merge with existing product fields
	existing, err := r.GetByID(ctx, p.ID)
	if err == nil && existing != nil {
		if p.Name == "" {
			p.Name = existing.Name
		}
		if p.Price <= 0 {
			p.Price = existing.Price
		}
		if p.Category == "" {
			p.Category = existing.Category
		}
		if p.ImageURL == nil || *p.ImageURL == "" {
			p.ImageURL = existing.ImageURL
		}
		if len(p.CustomizableOptions) == 0 {
			p.CustomizableOptions = existing.CustomizableOptions
		}
	}

	optJSON, _ := json.Marshal(p.CustomizableOptions)
	var query string

	if p.OperatorID != "" {
		query = `
			UPDATE public.products
			SET name = $1, price = $2, category = $3, is_available = $4, image_url = $5, customizable_options = $6::jsonb
			WHERE id = $7::uuid AND operator_id = $8::uuid`
		cmdTag, execErr := r.db.Pool.Exec(ctx, query,
			p.Name, p.Price, p.Category, p.IsAvailable, p.ImageURL, optJSON, p.ID, p.OperatorID,
		)
		err = execErr
		if err == nil && cmdTag.RowsAffected() > 0 {
			return nil
		}
	}

	fallbackQuery := `
		UPDATE public.products
		SET name = $1, price = $2, category = $3, is_available = $4, image_url = $5, customizable_options = $6::jsonb
		WHERE id = $7::uuid`
	_, err = r.db.Pool.Exec(ctx, fallbackQuery,
		p.Name, p.Price, p.Category, p.IsAvailable, p.ImageURL, optJSON, p.ID,
	)
	return err
}

func (r *ProductRepo) UpdateAvailability(ctx context.Context, id, operatorID string, isAvailable bool) error {
	if operatorID != "" {
		query := `UPDATE public.products SET is_available = $1 WHERE id = $2::uuid AND operator_id = $3::uuid`
		cmdTag, err := r.db.Pool.Exec(ctx, query, isAvailable, id, operatorID)
		if err == nil && cmdTag.RowsAffected() > 0 {
			return nil
		}
	}

	fallbackQuery := `UPDATE public.products SET is_available = $1 WHERE id = $2::uuid`
	_, err := r.db.Pool.Exec(ctx, fallbackQuery, isAvailable, id)
	return err
}

func (r *ProductRepo) Delete(ctx context.Context, id, operatorID string) error {
	if operatorID != "" {
		query := `DELETE FROM public.products WHERE id = $1::uuid AND operator_id = $2::uuid`
		cmdTag, err := r.db.Pool.Exec(ctx, query, id, operatorID)
		if err == nil && cmdTag.RowsAffected() > 0 {
			return nil
		}
	}

	fallbackQuery := `DELETE FROM public.products WHERE id = $1::uuid`
	_, err := r.db.Pool.Exec(ctx, fallbackQuery, id)
	return err
}
