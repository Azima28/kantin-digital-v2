package http

import (
	"encoding/json"
	"strings"
	"testing"

	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/token"
)

func strPtr(s string) *string { return &s }

// fixture builds a stall directory row exactly as ListCanteenOperators returns it:
// canteen data joined with the operator's public.profiles row.
func fixture() []domain.CanteenOperator {
	return []domain.CanteenOperator{
		{
			ID:            "op-1",
			CanteenName:   "Stan Bu Sri",
			BalanceEarned: 4500000,
			Profile: &domain.UserProfile{
				ID:          "op-1",
				Email:       strPtr("busri@sekolah.id"),
				FullName:    "Sri Wahyuni",
				Role:        domain.RolePetugasKantin,
				Username:    strPtr("busri"),
				PhoneNumber: strPtr("081234567890"),
				Gender:      strPtr("P"),
				IsActive:    true,
			},
		},
		{
			ID:            "op-2",
			CanteenName:   "Stan Pak Budi",
			BalanceEarned: 2750000,
			Profile: &domain.UserProfile{
				ID:          "op-2",
				Email:       strPtr("pakbudi@sekolah.id"),
				FullName:    "Budi Santoso",
				Role:        domain.RolePetugasKantin,
				Username:    strPtr("pakbudi"),
				PhoneNumber: strPtr("081298765432"),
				IsActive:    true,
			},
		},
	}
}

func assertSanitized(t *testing.T, c domain.CanteenOperator, label string) {
	t.Helper()
	if c.BalanceEarned != 0 {
		t.Errorf("%s: balance_earned leaked (%d), expected 0", label, c.BalanceEarned)
	}
	if c.Profile == nil {
		return
	}
	if c.Profile.Email != nil {
		t.Errorf("%s: email leaked (%s)", label, *c.Profile.Email)
	}
	if c.Profile.Username != nil {
		t.Errorf("%s: username leaked (%s)", label, *c.Profile.Username)
	}
	if c.Profile.PhoneNumber != nil {
		t.Errorf("%s: phone_number leaked (%s)", label, *c.Profile.PhoneNumber)
	}
	if c.Profile.Gender != nil {
		t.Errorf("%s: gender leaked (%s)", label, *c.Profile.Gender)
	}
	if c.Profile.NISN != nil {
		t.Errorf("%s: nisn leaked (%s)", label, *c.Profile.NISN)
	}
}

// Anonymous visitors must never receive operator credentials or revenue.
func TestSanitizeCanteenListAnonymous(t *testing.T) {
	got := sanitizeCanteenList(fixture(), nil)

	if len(got) != 2 {
		t.Fatalf("expected 2 stalls, got %d", len(got))
	}
	for i, c := range got {
		assertSanitized(t, c, "anonymous")
		// Public display fields must survive so the public menu still renders.
		if c.CanteenName == "" {
			t.Errorf("stall %d: canteen_name was stripped, public menu would break", i)
		}
		if c.ID == "" {
			t.Errorf("stall %d: id was stripped", i)
		}
	}
}

// Students and parents are authenticated but have no business seeing merchant
// credentials or earnings either.
func TestSanitizeCanteenListStudentAndParent(t *testing.T) {
	for _, role := range []domain.Role{domain.RoleStudent, domain.RoleParent} {
		got := sanitizeCanteenList(fixture(), &token.JWTClaims{UserID: "someone", Role: role})
		for _, c := range got {
			assertSanitized(t, c, string(role))
		}
	}
}

// A canteen operator keeps their own stall intact (the POS dashboard reads
// balance_earned from here) but must not see other operators' data.
func TestSanitizeCanteenListOperatorSeesOnlyOwnStall(t *testing.T) {
	got := sanitizeCanteenList(fixture(), &token.JWTClaims{UserID: "op-1", Role: domain.RolePetugasKantin})

	own := got[0]
	if own.BalanceEarned != 4500000 {
		t.Errorf("operator lost own balance_earned: got %d, want 4500000", own.BalanceEarned)
	}
	if own.Profile == nil || own.Profile.Email == nil || *own.Profile.Email != "busri@sekolah.id" {
		t.Errorf("operator lost access to own profile details")
	}

	assertSanitized(t, got[1], "operator viewing rival stall")
}

// Staff manage merchants, so they legitimately need the full records.
func TestSanitizeCanteenListStaffKeepsFullData(t *testing.T) {
	for _, role := range []domain.Role{domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan} {
		got := sanitizeCanteenList(fixture(), &token.JWTClaims{UserID: "staff-1", Role: role})
		for i, c := range got {
			if c.BalanceEarned == 0 {
				t.Errorf("%s: stall %d lost balance_earned, staff dashboard would break", role, i)
			}
			if c.Profile == nil || c.Profile.Email == nil || c.Profile.PhoneNumber == nil {
				t.Errorf("%s: stall %d lost profile details staff need", role, i)
			}
		}
	}
}

// Wire-level assertion: the JSON actually served to an anonymous caller must not
// contain any operator credential, contact detail, or revenue figure.
func TestListCanteensAnonymousWireFormatHasNoPII(t *testing.T) {
	payload, err := json.Marshal(sanitizeCanteenList(fixture(), nil))
	if err != nil {
		t.Fatalf("marshal failed: %v", err)
	}
	body := string(payload)

	forbidden := []string{
		"busri@sekolah.id", "pakbudi@sekolah.id", // emails
		"\"busri\"", "\"pakbudi\"", // login usernames
		"081234567890", "081298765432", // phone numbers
		"4500000", "2750000", // merchant revenue
		"password", // never serialized (domain tag is json:"-")
	}
	for _, needle := range forbidden {
		if strings.Contains(body, needle) {
			t.Errorf("anonymous payload leaks %q\nbody: %s", needle, body)
		}
	}

	// The public directory still has to be usable.
	for _, needle := range []string{"Stan Bu Sri", "Stan Pak Budi"} {
		if !strings.Contains(body, needle) {
			t.Errorf("anonymous payload is missing public field %q", needle)
		}
	}
}
