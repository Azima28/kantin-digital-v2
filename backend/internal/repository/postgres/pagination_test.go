package postgres

import (
	"testing"
)

// TestPaginationSliceWindow simulates lazy loading / cursor-based pagination calculation performance
func TestPaginationSliceWindow(t *testing.T) {
	totalItems := 1000
	items := make([]int, totalItems)
	for i := 0; i < totalItems; i++ {
		items[i] = i + 1
	}

	pageSize := 20
	pages := (totalItems + pageSize - 1) / pageSize

	for p := 0; p < pages; p++ {
		start := p * pageSize
		end := start + pageSize
		if end > totalItems {
			end = totalItems
		}
		pageItems := items[start:end]

		if len(pageItems) != pageSize && end != totalItems {
			t.Errorf("Page %d has wrong size %d", p, len(pageItems))
		}
	}
}

func BenchmarkPaginationSliceWindow(b *testing.B) {
	totalItems := 10000
	items := make([]int, totalItems)
	for i := 0; i < totalItems; i++ {
		items[i] = i
	}
	pageSize := 20

	b.ResetTimer()
	b.ReportAllocs()

	for i := 0; i < b.N; i++ {
		page := i % (totalItems / pageSize)
		start := page * pageSize
		end := start + pageSize
		_ = items[start:end]
	}
}
