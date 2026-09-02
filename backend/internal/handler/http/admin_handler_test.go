package http

import (
	"errors"
	"strings"
	"testing"

	"kantin-backend/internal/domain"
)

// The demo super_admin credentials are published on the login screen on purpose,
// so these two tables are the last line of defence for user management: an
// attacker holding that account must still not be able to mint a peer, take over
// the real owner's account, or lock them out.

func TestAssignableRolesBlocksPrivilegeEscalation(t *testing.T) {
	cases := []struct {
		caller domain.Role
		target domain.Role
		want   bool
	}{
		{domain.RoleSuperAdmin, domain.RoleSuperAdmin, true},
		{domain.RoleSuperAdmin, domain.RoleAdmin, true},
		{domain.RoleSuperAdmin, domain.RoleStudent, true},
		{domain.RoleAdmin, domain.RolePetugasKeuangan, true},
		{domain.RoleAdmin, domain.RoleAdmin, false},      // no minting a peer
		{domain.RoleAdmin, domain.RoleSuperAdmin, false}, // no minting a superior
		{domain.RolePetugasKeuangan, domain.RoleStudent, true},
		{domain.RolePetugasKeuangan, domain.RoleParent, true},
		{domain.RolePetugasKeuangan, domain.RolePetugasKeuangan, false},
		{domain.RolePetugasKeuangan, domain.RoleSuperAdmin, false}, // the escalation this fixes
		{domain.RolePetugasKantin, domain.RoleStudent, false},      // not a user manager at all
		{domain.RoleStudent, domain.RoleStudent, false},
		{domain.RoleParent, domain.RoleSuperAdmin, false},
	}
	for _, tc := range cases {
		if got := assignableRoles[tc.caller][tc.target]; got != tc.want {
			t.Errorf("%s membuat %s: dapat %v, ingin %v", tc.caller, tc.target, got, tc.want)
		}
	}
}

func TestRoleRankOrdering(t *testing.T) {
	if !(roleRank(domain.RoleSuperAdmin) > roleRank(domain.RoleAdmin) &&
		roleRank(domain.RoleAdmin) > roleRank(domain.RolePetugasKeuangan) &&
		roleRank(domain.RolePetugasKeuangan) > roleRank(domain.RoleStudent)) {
		t.Fatal("urutan peringkat peran tidak monoton")
	}
	if roleRank(domain.RolePetugasKeuangan) != roleRank(domain.RolePetugasKantin) {
		t.Error("petugas keuangan dan petugas kantin harus sederajat")
	}
	if roleRank(domain.Role("hacker")) != 0 {
		t.Error("peran tak dikenal harus mendapat peringkat terendah")
	}
}

func profile(id string, role domain.Role) *domain.UserProfile {
	return &domain.UserProfile{ID: id, FullName: "Target", Role: role, IsActive: true}
}

func TestAuthorizeUserMutationRequiresStrictlyHigherRank(t *testing.T) {
	cases := []struct {
		name      string
		caller    domain.Role
		callerID  string
		target    *domain.UserProfile
		allowSelf bool
		wantErr   bool
	}{
		{"super admin ubah admin", domain.RoleSuperAdmin, "sa-1", profile("ad-1", domain.RoleAdmin), false, false},
		{"super admin ubah super admin lain", domain.RoleSuperAdmin, "sa-1", profile("sa-2", domain.RoleSuperAdmin), false, true},
		{"super admin ubah dirinya sendiri", domain.RoleSuperAdmin, "sa-1", profile("sa-1", domain.RoleSuperAdmin), true, false},
		{"super admin hapus dirinya sendiri", domain.RoleSuperAdmin, "sa-1", profile("sa-1", domain.RoleSuperAdmin), false, true},
		{"admin ubah admin lain", domain.RoleAdmin, "ad-1", profile("ad-2", domain.RoleAdmin), false, true},
		{"admin ubah siswa", domain.RoleAdmin, "ad-1", profile("st-1", domain.RoleStudent), false, false},
		{"keuangan ubah admin", domain.RolePetugasKeuangan, "fo-1", profile("ad-1", domain.RoleAdmin), false, true},
		{"keuangan ubah siswa", domain.RolePetugasKeuangan, "fo-1", profile("st-1", domain.RoleStudent), false, false},
		{"siswa ubah siswa lain", domain.RoleStudent, "st-1", profile("st-2", domain.RoleStudent), false, true},
		{"target tidak ada", domain.RoleSuperAdmin, "sa-1", nil, true, true},
	}
	for _, tc := range cases {
		err := authorizeUserMutation(tc.caller, tc.callerID, tc.target, tc.allowSelf)
		if (err != nil) != tc.wantErr {
			t.Errorf("%s: dapat error %v, ingin error %v", tc.name, err, tc.wantErr)
		}
	}
}

func TestAuthorizeUserMutationSelfMatchIsCaseInsensitive(t *testing.T) {
	target := profile("A1B2-C3D4", domain.RoleAdmin)
	if err := authorizeUserMutation(domain.RoleAdmin, "a1b2-c3d4", target, true); err != nil {
		t.Errorf("UUID dengan besar-kecil huruf berbeda harus dikenali sebagai diri sendiri: %v", err)
	}
}

// An audit row must never become a second place to steal a password hash from.
func TestAuditUserSnapshotNeverCarriesPassword(t *testing.T) {
	secret := "$2a$10$hashyanghurusrahasia"
	email := "ops@sekolah.id"
	u := &domain.UserProfile{
		ID: "u-1", FullName: "Petugas", Role: domain.RolePetugasKeuangan,
		Password: &secret, Email: &email, IsActive: true,
	}

	snap := auditUserSnapshot(u)
	for key := range snap {
		if strings.Contains(strings.ToLower(key), "password") {
			t.Fatalf("snapshot audit memuat kunci %q", key)
		}
	}

	encoded := auditJSON(snap)
	if strings.Contains(encoded, secret) {
		t.Fatal("hash kata sandi ikut tertulis ke log audit")
	}
	if !strings.Contains(encoded, email) {
		t.Error("snapshot audit kehilangan data yang memang perlu dicatat")
	}
	if got := auditJSON(auditUserSnapshot(nil)); got != "{}" {
		t.Errorf("snapshot nil harus menghasilkan {}, dapat %s", got)
	}
}

func boolPtr(b bool) *bool { return &b }

// TestApplyUserPatchKeepsOmittedFields is why every field of UpdateUserRequest is
// a pointer. A PATCH that only carries full_name must not blank the phone number,
// the NISN or the active flag just because those keys were absent from the body.
func TestApplyUserPatchKeepsOmittedFields(t *testing.T) {
	secret := "$2a$10$hashyanghurusrahasia"
	stored := &domain.UserProfile{
		ID:          "u-1",
		FullName:    "Budi Keuangan",
		Role:        domain.RolePetugasKeuangan,
		Password:    &secret,
		Email:       strPtr("budi@sekolah.id"),
		Username:    strPtr("budi_fin"),
		NISN:        strPtr("20260012"),
		PhoneNumber: strPtr("08123456789"),
		AvatarURL:   strPtr("https://cdn/avatar.png"),
		Relation:    strPtr("ayah"),
		Gender:      strPtr("L"),
		IsActive:    true,
	}

	merged, err := applyUserPatch(stored, UpdateUserRequest{FullName: strPtr("Budi Santoso")})
	if err != nil {
		t.Fatalf("applyUserPatch gagal: %v", err)
	}

	if merged.FullName != "Budi Santoso" {
		t.Errorf("full_name tidak diterapkan: %q", merged.FullName)
	}
	if merged.Password != nil {
		t.Error("hash kata sandi terbawa ke hasil patch dan bisa bocor lewat response")
	}
	if merged.Role != domain.RolePetugasKeuangan {
		t.Errorf("peran berubah menjadi %q padahal tidak ada di payload", merged.Role)
	}
	if merged.ID != stored.ID {
		t.Errorf("id berubah menjadi %q", merged.ID)
	}
	if !merged.IsActive {
		t.Error("is_active yang tidak dikirim malah jadi false")
	}
	for name, pair := range map[string][2]*string{
		"email":        {merged.Email, stored.Email},
		"username":     {merged.Username, stored.Username},
		"nisn":         {merged.NISN, stored.NISN},
		"phone_number": {merged.PhoneNumber, stored.PhoneNumber},
		"avatar_url":   {merged.AvatarURL, stored.AvatarURL},
		"relation":     {merged.Relation, stored.Relation},
		"gender":       {merged.Gender, stored.Gender},
	} {
		got, want := pair[0], pair[1]
		if got == nil || want == nil || *got != *want {
			t.Errorf("%s hilang setelah patch parsial", name)
		}
	}

	// The stored profile itself must not be mutated -- the handler still logs it
	// as the audit "before" snapshot after the merge.
	if stored.FullName != "Budi Keuangan" || stored.Password == nil {
		t.Error("applyUserPatch mengubah objek asal, snapshot audit sebelum-sesudah jadi rusak")
	}
}

func TestApplyUserPatchRejectsEmptyFullName(t *testing.T) {
	stored := profile("u-1", domain.RoleStudent)

	for _, blank := range []string{"", "   ", "\t\n"} {
		if _, err := applyUserPatch(stored, UpdateUserRequest{FullName: strPtr(blank)}); !errors.Is(err, errEmptyFullName) {
			t.Errorf("full_name %q diterima, mau ditolak (dapat err=%v)", blank, err)
		}
	}

	// A name that is only padded must be accepted and stored trimmed, otherwise a
	// trailing space becomes a second, look-alike account name.
	merged, err := applyUserPatch(stored, UpdateUserRequest{FullName: strPtr("  Ahmad Siswa  ")})
	if err != nil {
		t.Fatalf("applyUserPatch gagal: %v", err)
	}
	if merged.FullName != "Ahmad Siswa" {
		t.Errorf("full_name tidak dipangkas: %q", merged.FullName)
	}
}

func TestApplyUserPatchAppliesExplicitValues(t *testing.T) {
	stored := &domain.UserProfile{
		ID: "u-2", FullName: "Ahmad", Role: domain.RoleStudent, IsActive: true,
		Email: strPtr("lama@sekolah.id"), Gender: strPtr("L"),
	}

	merged, err := applyUserPatch(stored, UpdateUserRequest{
		Email:    strPtr("baru@sekolah.id"),
		Gender:   strPtr("P"),
		IsActive: boolPtr(false),
	})
	if err != nil {
		t.Fatalf("applyUserPatch gagal: %v", err)
	}
	if merged.Email == nil || *merged.Email != "baru@sekolah.id" {
		t.Error("email baru tidak diterapkan")
	}
	if merged.Gender == nil || *merged.Gender != "P" {
		t.Error("gender baru tidak diterapkan")
	}
	// A *bool is what lets false be told apart from "key absent"; a plain bool
	// would silently deactivate every user who was patched for another reason.
	if merged.IsActive {
		t.Error("is_active: false diabaikan")
	}
	if merged.FullName != "Ahmad" {
		t.Errorf("full_name berubah tanpa diminta: %q", merged.FullName)
	}
}

func TestApplyUserPatchRejectsMissingTarget(t *testing.T) {
	if _, err := applyUserPatch(nil, UpdateUserRequest{FullName: strPtr("Siapa Saja")}); err == nil {
		t.Fatal("patch terhadap pengguna yang tidak ada harus gagal")
	}
}
