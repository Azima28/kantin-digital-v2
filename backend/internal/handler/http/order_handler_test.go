package http

import (
	"encoding/json"
	"strings"
	"testing"

	"kantin-backend/internal/domain"
)

func avatarPtr(s string) *string { return &s }

// anonReview mirrors what OrderService.SubmitReview hands back: the row it just
// inserted, with student_id and student_name filled in from the caller's JWT.
func anonReview(anonymous bool) *domain.OrderReview {
	operatorID := "op-1"
	return &domain.OrderReview{
		ID:          "rev-1",
		OrderID:     "ord-deadbeef",
		StudentID:   "stu-cafebabe",
		StudentName: "Budi Hartono",
		AvatarURL:   avatarPtr("https://cdn/avatar/budi.png"),
		OperatorID:  &operatorID,
		Rating:      2,
		ReviewText:  "Lama sekali menunggu.",
		Tags:        []string{"lambat"},
		IsAnonymous: anonymous,
	}
}

// An anonymous review broadcast to the stall's operator room must carry no handle
// back to the buyer.
func TestSanitizeReviewForBroadcastAnonymousDropsIdentity(t *testing.T) {
	got := sanitizeReviewForBroadcast(anonReview(true))

	if got.StudentID != "" {
		t.Errorf("student_id leaked over websocket: %q", got.StudentID)
	}
	if got.OrderID != "" {
		t.Errorf("order_id leaked over websocket: %q", got.OrderID)
	}
	if got.StudentName != "Siswa (Anonim)" {
		t.Errorf("student_name = %q, want %q", got.StudentName, "Siswa (Anonim)")
	}
	if got.AvatarURL != nil {
		t.Errorf("avatar_url leaked over websocket: %q", *got.AvatarURL)
	}
	// The operator still needs the review itself to be useful.
	if got.Rating != 2 || got.ReviewText != "Lama sekali menunggu." || len(got.Tags) != 1 {
		t.Errorf("review content was damaged: %+v", got)
	}
	if got.OperatorID == nil || *got.OperatorID != "op-1" {
		t.Errorf("operator_id was stripped, the broadcast could not be routed")
	}
}

// A named review is broadcast as-is; the student chose to be credited.
func TestSanitizeReviewForBroadcastNamedKeepsIdentity(t *testing.T) {
	got := sanitizeReviewForBroadcast(anonReview(false))

	if got.StudentName != "Budi Hartono" {
		t.Errorf("student_name = %q, want %q", got.StudentName, "Budi Hartono")
	}
	if got.StudentID != "stu-cafebabe" || got.OrderID != "ord-deadbeef" {
		t.Errorf("named review lost its ids: %+v", got)
	}
	if got.AvatarURL == nil {
		t.Errorf("named review lost its avatar")
	}
}

// Sanitizing must not mutate the object the HTTP response still has to serve to
// the reviewing student.
func TestSanitizeReviewForBroadcastDoesNotMutateOriginal(t *testing.T) {
	original := anonReview(true)
	_ = sanitizeReviewForBroadcast(original)

	if original.StudentID != "stu-cafebabe" || original.OrderID != "ord-deadbeef" {
		t.Errorf("sanitizer mutated the response payload: %+v", original)
	}
	if original.StudentName != "Budi Hartono" {
		t.Errorf("sanitizer mutated student_name on the response payload")
	}
}

func TestSanitizeReviewForBroadcastNilIsSafe(t *testing.T) {
	if got := sanitizeReviewForBroadcast(nil); got != nil {
		t.Errorf("expected nil passthrough, got %+v", got)
	}
}

// Wire-level assertion: the JSON frame pushed to order:<id> and canteen:<opId>
// must not contain the reviewer's name, id, avatar, or order id.
func TestAnonymousReviewBroadcastFrameHasNoReviewerHandles(t *testing.T) {
	payload, err := json.Marshal(sanitizeReviewForBroadcast(anonReview(true)))
	if err != nil {
		t.Fatalf("marshal failed: %v", err)
	}
	body := string(payload)

	for _, needle := range []string{"stu-cafebabe", "ord-deadbeef", "Budi Hartono", "cdn/avatar"} {
		if strings.Contains(body, needle) {
			t.Errorf("broadcast frame leaks %q\nframe: %s", needle, body)
		}
	}
	for _, needle := range []string{"Lama sekali", "Siswa (Anonim)", "lambat"} {
		if !strings.Contains(body, needle) {
			t.Errorf("broadcast frame is missing %q", needle)
		}
	}
}
