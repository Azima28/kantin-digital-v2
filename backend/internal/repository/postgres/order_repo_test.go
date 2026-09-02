package postgres

import (
	"encoding/json"
	"strings"
	"testing"

	"kantin-backend/internal/domain"
)

func sptr(s string) *string { return &s }

// An anonymous review must not carry any handle back to the student. Blanking
// only the display name still leaves student_id and order_id in the payload,
// which is enough to re-identify the reviewer.
func TestApplyReviewIdentityAnonymousDropsAllHandles(t *testing.T) {
	rev := domain.OrderReview{
		ID:          "rev-1",
		OrderID:     "ord-9c1f",
		StudentID:   "stu-4b2a",
		Rating:      2,
		ReviewText:  "Porsinya kurang",
		IsAnonymous: true,
	}

	applyReviewIdentity(&rev, sptr("Ahmad Fauzi"), sptr("https://cdn/avatar/stu-4b2a.png"))

	if rev.StudentID != "" {
		t.Errorf("student_id leaked on anonymous review: %q", rev.StudentID)
	}
	if rev.OrderID != "" {
		t.Errorf("order_id leaked on anonymous review: %q", rev.OrderID)
	}
	if rev.StudentName != "Siswa (Anonim)" {
		t.Errorf("student_name = %q, want %q", rev.StudentName, "Siswa (Anonim)")
	}
	if rev.AvatarURL != nil {
		t.Errorf("avatar_url leaked on anonymous review: %q", *rev.AvatarURL)
	}
	// The review itself still has to be displayable.
	if rev.Rating != 2 || rev.ReviewText != "Porsinya kurang" {
		t.Errorf("review content was damaged: rating=%d text=%q", rev.Rating, rev.ReviewText)
	}
	if rev.ID == "" {
		t.Error("review id was stripped, the list would lose its keys")
	}
}

// A non-anonymous review is unchanged: the student chose to be named.
func TestApplyReviewIdentityNamedKeepsIdentity(t *testing.T) {
	rev := domain.OrderReview{
		ID:          "rev-2",
		OrderID:     "ord-7a55",
		StudentID:   "stu-1188",
		Rating:      5,
		IsAnonymous: false,
	}

	applyReviewIdentity(&rev, sptr("Siti Nurhaliza"), sptr("https://cdn/avatar/stu-1188.png"))

	if rev.StudentName != "Siti Nurhaliza" {
		t.Errorf("student_name = %q, want the real name", rev.StudentName)
	}
	if rev.AvatarURL == nil {
		t.Error("avatar_url was dropped for a named reviewer")
	}
	if rev.StudentID != "stu-1188" || rev.OrderID != "ord-7a55" {
		t.Error("named review lost its ids")
	}
}

// A deleted profile leaves full_name NULL; the review must still render.
func TestApplyReviewIdentityNamedWithMissingProfile(t *testing.T) {
	rev := domain.OrderReview{ID: "rev-3", StudentID: "stu-gone", Rating: 4}

	applyReviewIdentity(&rev, nil, nil)

	if rev.StudentName != "" {
		t.Errorf("student_name = %q, want empty so the client falls back to 'Siswa'", rev.StudentName)
	}
}

// Wire-level check: the JSON served for an anonymous review contains no
// identifier of the reviewer.
func TestAnonymousReviewWireFormatHasNoReviewerHandles(t *testing.T) {
	rev := domain.OrderReview{
		ID:          "rev-4",
		OrderID:     "ord-deadbeef",
		StudentID:   "stu-cafebabe",
		Rating:      1,
		ReviewText:  "Lama sekali",
		Tags:        []string{"lambat"},
		IsAnonymous: true,
	}
	applyReviewIdentity(&rev, sptr("Budi Hartono"), sptr("https://cdn/avatar/stu-cafebabe.png"))

	payload, err := json.Marshal(rev)
	if err != nil {
		t.Fatalf("marshal failed: %v", err)
	}
	body := string(payload)

	for _, needle := range []string{"stu-cafebabe", "ord-deadbeef", "Budi Hartono", "cdn/avatar"} {
		if strings.Contains(body, needle) {
			t.Errorf("anonymous review payload leaks %q\nbody: %s", needle, body)
		}
	}
	for _, needle := range []string{"Lama sekali", "Siswa (Anonim)", "lambat"} {
		if !strings.Contains(body, needle) {
			t.Errorf("anonymous review payload is missing displayable field %q", needle)
		}
	}
}
