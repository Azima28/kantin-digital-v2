package http

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/handler/http/middleware"
	ws "kantin-backend/internal/handler/websocket"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
	"kantin-backend/internal/service"
)

// assignableRoles maps a caller's role to the roles it may hand out when creating
// an account. CreateUser used to take domain.Role straight from the request body,
// and the same handler is mounted under /finance/users for petugas_keuangan, so a
// finance officer could POST {"role":"super_admin"} and own the whole system.
var assignableRoles = map[domain.Role]map[domain.Role]bool{
	domain.RoleSuperAdmin: {
		domain.RoleStudent:         true,
		domain.RoleParent:          true,
		domain.RolePetugasKantin:   true,
		domain.RolePetugasKeuangan: true,
		domain.RoleAdmin:           true,
		domain.RoleSuperAdmin:      true,
	},
	domain.RoleAdmin: {
		domain.RoleStudent:         true,
		domain.RoleParent:          true,
		domain.RolePetugasKantin:   true,
		domain.RolePetugasKeuangan: true,
	},
	domain.RolePetugasKeuangan: {
		domain.RoleStudent: true,
		domain.RoleParent:  true,
	},
}

// roleRank orders roles by privilege so a caller cannot reach sideways or upwards.
func roleRank(r domain.Role) int {
	switch r {
	case domain.RoleSuperAdmin:
		return 3
	case domain.RoleAdmin:
		return 2
	case domain.RolePetugasKeuangan, domain.RolePetugasKantin:
		return 1
	default:
		return 0
	}
}

// authorizeUserMutation reports whether the caller may mutate the target profile.
// Strictly-greater rank is required, so an admin cannot reset another admin's
// password and -- because the demo super_admin credentials are published on the
// login screen on purpose -- nobody can take over or delete another super_admin
// account through these endpoints. allowSelf covers the operations that make
// sense on your own account (editing your profile, resetting your own password)
// but never deletion.
func authorizeUserMutation(callerRole domain.Role, callerID string, target *domain.UserProfile, allowSelf bool) error {
	if target == nil {
		return fmt.Errorf("pengguna tidak ditemukan")
	}
	if allowSelf && strings.EqualFold(callerID, target.ID) {
		return nil
	}
	if roleRank(callerRole) <= roleRank(target.Role) {
		return fmt.Errorf("akses ditolak: Anda tidak berwenang mengubah akun dengan peran %s", target.Role)
	}
	return nil
}

// auditUserSnapshot describes a profile for the audit trail. The password hash is
// deliberately absent -- an audit row must never become a second place to steal
// credentials from.
func auditUserSnapshot(u *domain.UserProfile) map[string]interface{} {
	if u == nil {
		return map[string]interface{}{}
	}
	return map[string]interface{}{
		"id":           u.ID,
		"full_name":    u.FullName,
		"role":         u.Role,
		"email":        u.Email,
		"username":     u.Username,
		"nisn":         u.NISN,
		"phone_number": u.PhoneNumber,
		"gender":       u.Gender,
		"relation":     u.Relation,
		"is_active":    u.IsActive,
	}
}

func auditJSON(v interface{}) string {
	b, err := json.Marshal(v)
	if err != nil {
		return "{}"
	}
	return string(b)
}

// adminClaims returns the authenticated caller. Every route in this file sits
// behind authRequired, so the claims are always present; the nil branch only
// guards against a future route being mounted outside that group.
func adminClaims(c *fiber.Ctx) *token.JWTClaims {
	claims, _ := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	return claims
}

type AdminHandler struct {
	paymentService *service.PaymentService
	catalogService *service.CatalogService
	sessionRepo    *postgres.SessionRepo
	hub            *ws.Hub
}

func NewAdminHandler(paymentService *service.PaymentService, catalogService *service.CatalogService, sessionRepo *postgres.SessionRepo, hub ...*ws.Hub) *AdminHandler {
	var h *ws.Hub
	if len(hub) > 0 {
		h = hub[0]
	}
	return &AdminHandler{
		paymentService: paymentService,
		catalogService: catalogService,
		sessionRepo:    sessionRepo,
		hub:            h,
	}
}

// revokeTargetSessions ends every session the given account currently holds.
//
// A forced password reset or a deactivation that leaves the target's existing
// tokens working is only half an intervention: the account stays usable by
// whoever already has one until it expires on its own. Failure is reported to the
// caller rather than swallowed, because the caller needs to know the lockout did
// not actually take effect.
func (h *AdminHandler) revokeTargetSessions(c *fiber.Ctx, userID string) error {
	if h.sessionRepo == nil {
		return nil
	}
	return h.sessionRepo.RevokeAllForUser(c.Context(), userID, time.Now())
}

func (h *AdminHandler) Dashboard(c *fiber.Ctx) error {
	summary, err := h.paymentService.GetAdminSummary(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat ringkasan admin", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Ringkasan dasbor admin", summary)
}

func (h *AdminHandler) ListUsers(c *fiber.Ctx) error {
	role := c.Query("role", "")
	users, err := h.paymentService.ListAllUsers(c.Context(), role)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat daftar pengguna", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Daftar pengguna", users)
}

type CreateUserRequest struct {
	FullName    string      `json:"full_name"`
	Email       *string     `json:"email"`
	Username    *string     `json:"username"`
	Password    string      `json:"password"`
	Role        domain.Role `json:"role"`
	NISN        *string     `json:"nisn"`
	PhoneNumber *string     `json:"phone_number"`
	Relation    *string     `json:"relation"`
	StudentNISN *string     `json:"student_nisn"`
	CanteenName string      `json:"canteen_name"`
	RfidUID     *string     `json:"rfid_uid"`
	Class       *string     `json:"class"`
	Gender      *string     `json:"gender"`
}

func (h *AdminHandler) CreateUser(c *fiber.Ctx) error {
	var req CreateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload pengguna tidak valid", err.Error())
	}

	if req.FullName == "" {
		return response.Error(c, fiber.StatusBadRequest, "Nama lengkap wajib diisi", nil)
	}

	// Default role to student if endpoint was /admin/students or role empty
	if req.Role == "" {
		req.Role = domain.RoleStudent
	}

	claims := adminClaims(c)
	if claims == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}
	if !assignableRoles[claims.Role][req.Role] {
		return response.Error(c, fiber.StatusForbidden,
			fmt.Sprintf("Akses ditolak: peran %q tidak dapat Anda tetapkan", req.Role), nil)
	}

	user := &domain.UserProfile{
		FullName:    req.FullName,
		Email:       req.Email,
		Username:    req.Username,
		Role:        req.Role,
		NISN:        req.NISN,
		PhoneNumber: req.PhoneNumber,
		Relation:    req.Relation,
		Gender:      req.Gender,
		IsActive:    true,
	}

	tempPassword, err := h.paymentService.CreateUser(c.Context(), user, req.Password, req.CanteenName, req.RfidUID, req.StudentNISN, req.Class)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menambahkan pengguna: "+err.Error(), err.Error())
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "USER_CREATED", "profiles",
		user.ID, "", auditJSON(auditUserSnapshot(user)), c.IP())

	// A generated password has to reach the operator somehow, and this response is
	// the only chance: it is hashed on the way into the database and cannot be read
	// back. It rides in the message rather than the payload so that existing clients,
	// which read the created profile out of data, keep working.
	message := "Pengguna berhasil ditambahkan"
	if tempPassword != "" {
		message = "Pengguna berhasil ditambahkan. Kata sandi sementara: " + tempPassword + " (catat sekarang, tidak dapat dilihat lagi)"
	}

	return response.Success(c, fiber.StatusCreated, message, user)
}

type UpdateUserStatusRequest struct {
	IsActive bool `json:"is_active"`
}

func (h *AdminHandler) UpdateStatus(c *fiber.Ctx) error {
	id := c.Params("id")
	var req UpdateUserStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}

	claims := adminClaims(c)
	if claims == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}
	// Deactivating an account is a lockout, so the same rank rule as the other
	// mutations applies: no reaching sideways or upwards. Self is excluded too --
	// locking yourself out is never the intent behind this endpoint.
	target, err := h.paymentService.GetUserByID(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Pengguna tidak ditemukan", err.Error())
	}
	if strings.EqualFold(claims.UserID, target.ID) {
		return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Anda tidak dapat mengubah status akun Anda sendiri", nil)
	}
	if err := authorizeUserMutation(claims.Role, claims.UserID, target, false); err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}

	if err := h.paymentService.UpdateUserStatus(c.Context(), id, req.IsActive); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengubah status: "+err.Error(), err.Error())
	}

	// The middleware already refuses a deactivated account on its next request, but
	// only while it can reach the database. Revoking the sessions outright means the
	// lockout does not depend on that lookup succeeding.
	if !req.IsActive {
		if err := h.revokeTargetSessions(c, id); err != nil {
			return response.Error(c, fiber.StatusInternalServerError,
				"Status diperbarui, tetapi sesi aktif pengguna gagal dihentikan. Ulangi aksi ini.", err.Error())
		}
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "USER_STATUS_CHANGED", "profiles", id,
		auditJSON(map[string]interface{}{"is_active": target.IsActive}),
		auditJSON(map[string]interface{}{"is_active": req.IsActive}), c.IP())

	if h.hub != nil {
		h.hub.BroadcastToRoom(fmt.Sprintf("student:%s", id), "account_status_changed", fiber.Map{
			"user_id":   id,
			"is_active": req.IsActive,
		})
		h.hub.BroadcastToRoom(fmt.Sprintf("canteen:%s", id), "account_status_changed", fiber.Map{
			"user_id":   id,
			"is_active": req.IsActive,
		})
		h.hub.BroadcastToRoom(id, "account_status_changed", fiber.Map{
			"user_id":   id,
			"is_active": req.IsActive,
		})
	}

	return response.Success(c, fiber.StatusOK, "Status pengguna berhasil diperbarui", nil)
}

type AdminChangePasswordRequest struct {
	UserID      string `json:"user_id"`
	NewPassword string `json:"new_password"`
}

func (h *AdminHandler) AdminChangePassword(c *fiber.Ctx) error {
	var req AdminChangePasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}
	if req.UserID == "" || req.NewPassword == "" {
		return response.Error(c, fiber.StatusBadRequest, "User ID dan kata sandi baru wajib diisi", nil)
	}
	if len([]rune(req.NewPassword)) < 8 {
		return response.Error(c, fiber.StatusBadRequest, "Kata sandi baru minimal 8 karakter", nil)
	}

	claims := adminClaims(c)
	if claims == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}
	// A password reset is a full account takeover, so check WHO is being reset
	// before doing it. Previously any admin -- or anyone holding the published
	// demo credentials -- could rewrite the super_admin password and lock the real
	// owner out of their own system.
	target, err := h.paymentService.GetUserByID(c.Context(), req.UserID)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Pengguna tidak ditemukan", err.Error())
	}
	if err := authorizeUserMutation(claims.Role, claims.UserID, target, true); err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}

	if err := h.paymentService.AdminChangePassword(c.Context(), req.UserID, req.NewPassword); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengubah kata sandi: "+err.Error(), err.Error())
	}

	if err := h.revokeTargetSessions(c, req.UserID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError,
			"Kata sandi diperbarui, tetapi sesi lama pengguna gagal dihentikan. Ulangi aksi ini.", err.Error())
	}

	// The new password itself is never written to the audit trail, only the fact
	// that it was reset, by whom, and against which account.
	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "USER_PASSWORD_RESET", "profiles", req.UserID, "",
		auditJSON(map[string]interface{}{"target_role": target.Role, "target_name": target.FullName}), c.IP())

	return response.Success(c, fiber.StatusOK, "Kata sandi berhasil diperbarui", nil)
}

type AdminChangePinRequest struct {
	UserID string `json:"user_id"`
	Pin    string `json:"pin"`
}

func (h *AdminHandler) AdminChangeStudentPin(c *fiber.Ctx) error {
	var req AdminChangePinRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}
	if req.UserID == "" {
		req.UserID = c.Params("id")
	}
	if req.UserID == "" || req.Pin == "" {
		return response.Error(c, fiber.StatusBadRequest, "User ID dan PIN baru wajib diisi", nil)
	}

	claims := adminClaims(c)
	if claims == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}

	if claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RoleAdmin && claims.Role != domain.RolePetugasKeuangan {
		return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Hanya Admin dan Petugas Keuangan yang berwenang mereset PIN", nil)
	}

	target, err := h.paymentService.GetUserByID(c.Context(), req.UserID)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Pengguna tidak ditemukan", err.Error())
	}
	if target.Role != domain.RoleStudent {
		return response.Error(c, fiber.StatusBadRequest, "Reset PIN hanya berlaku untuk akun siswa", nil)
	}

	if err := h.paymentService.AdminChangeStudentPin(c.Context(), req.UserID, req.Pin); err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "STUDENT_PIN_RESET", "students", req.UserID, "",
		auditJSON(map[string]interface{}{
			"target_name": target.FullName,
			"target_role": target.Role,
			"actor_role":  claims.Role,
		}), c.IP())

	return response.Success(c, fiber.StatusOK, "PIN transaksi siswa berhasil diperbarui", nil)
}

type UpdateStudentRequest struct {
	FullName    string  `json:"full_name"`
	Email       *string `json:"email"`
	Username    *string `json:"username"`
	NISN        *string `json:"nisn"`
	PhoneNumber *string `json:"phone_number"`
	DailyLimit  *int    `json:"daily_limit"`
	RfidUID     *string `json:"rfid_uid"`
	Class       *string `json:"class"`
	IsActive    *bool   `json:"is_active"`
	Gender      *string `json:"gender"`
}

func (h *AdminHandler) UpdateStudent(c *fiber.Ctx) error {
	id := c.Params("id")
	var req UpdateStudentRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload update siswa tidak valid", err.Error())
	}

	claims := adminClaims(c)
	if claims == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}

	target, err := h.paymentService.GetUserByID(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
	}
	if err := authorizeUserMutation(claims.Role, claims.UserID, target, false); err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}

	params := postgres.UpdateStudentFullParams{
		ID:          id,
		FullName:    req.FullName,
		Email:       req.Email,
		Username:    req.Username,
		NISN:        req.NISN,
		PhoneNumber: req.PhoneNumber,
		DailyLimit:  req.DailyLimit,
		RfidUID:     req.RfidUID,
		Class:       req.Class,
		IsActive:    req.IsActive,
		Gender:      req.Gender,
	}

	if err := h.paymentService.UpdateStudentFull(c.Context(), params); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui data siswa: "+err.Error(), err.Error())
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "STUDENT_PROFILE_UPDATED", "profiles", id,
		auditJSON(map[string]interface{}{"full_name": target.FullName}),
		auditJSON(map[string]interface{}{"full_name": req.FullName}), c.IP())

	if h.hub != nil {
		h.hub.BroadcastToRoom(fmt.Sprintf("student:%s", id), "student_updated", fiber.Map{"student_id": id})
		h.hub.BroadcastToRoom(id, "student_updated", fiber.Map{"student_id": id})
	}

	return response.Success(c, fiber.StatusOK, "Profil siswa berhasil diperbarui", nil)
}

// UpdateUserRequest is a patch document: every field is a pointer, so a key that
// is absent from the body means "leave this column alone".
//
// The handler used to bind the body straight into a domain.UserProfile and pass
// it to an UPDATE that writes every column unconditionally. Any field the client
// omitted was therefore written back as its zero value, so a PATCH carrying only
// {"full_name":"x"} silently erased the target's email, username, NISN, phone and
// avatar -- and since is_active is a plain bool, "absent" was indistinguishable
// from false, which also deactivated the account. Pointers are what make the
// difference between "not sent" and "sent as empty" observable.
//
// Role is deliberately not patchable here: changing a role is a privilege change,
// not a profile edit, and the UPDATE behind this endpoint does not touch the role
// column at all.
type UpdateUserRequest struct {
	FullName    *string `json:"full_name"`
	Email       *string `json:"email"`
	Username    *string `json:"username"`
	NISN        *string `json:"nisn"`
	PhoneNumber *string `json:"phone_number"`
	AvatarURL   *string `json:"avatar_url"`
	Relation    *string `json:"relation"`
	Gender      *string `json:"gender"`
	IsActive    *bool   `json:"is_active"`
}

func (h *AdminHandler) UpdateUser(c *fiber.Ctx) error {
	id := c.Params("id")
	var req UpdateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload update tidak valid", err.Error())
	}

	claims := adminClaims(c)
	if claims == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}

	current, err := h.paymentService.GetUserByID(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Pengguna tidak ditemukan", err.Error())
	}
	if err := authorizeUserMutation(claims.Role, claims.UserID, current, true); err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}

	merged, err := applyUserPatch(current, req)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}
	merged.ID = id

	if err := h.paymentService.UpdateUser(c.Context(), merged); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui pengguna", err.Error())
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "USER_UPDATED", "profiles", id,
		auditJSON(auditUserSnapshot(current)), auditJSON(auditUserSnapshot(merged)), c.IP())

	return response.Success(c, fiber.StatusOK, "Pengguna berhasil diperbarui", merged)
}

func (h *AdminHandler) DeleteUser(c *fiber.Ctx) error {
	id := c.Params("id")

	claims := adminClaims(c)
	if claims == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}

	// profiles is the parent of eleven ON DELETE CASCADE relationships, so this one
	// request can take a person's whole transaction and order history with it. Hence
	// three gates: not yourself, not an account at or above your own rank, and (in
	// the service layer) not an account that still has financial history.
	target, err := h.paymentService.GetUserByID(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Pengguna tidak ditemukan", err.Error())
	}
	if strings.EqualFold(claims.UserID, target.ID) {
		return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Anda tidak dapat menghapus akun Anda sendiri", nil)
	}
	if err := authorizeUserMutation(claims.Role, claims.UserID, target, false); err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}

	if err := h.paymentService.DeleteUser(c.Context(), id); err != nil {
		return response.Error(c, fiber.StatusConflict, err.Error(), err.Error())
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "USER_DELETED", "profiles", id,
		auditJSON(auditUserSnapshot(target)), "", c.IP())

	return response.Success(c, fiber.StatusOK, "Pengguna berhasil dihapus", nil)
}

func (h *AdminHandler) ListAuditLogs(c *fiber.Ctx) error {
	limitStr := c.Query("limit", "100")
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 {
		limit = 100
	}

	logs, err := h.paymentService.ListAllAuditLogs(c.Context(), limit)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat log audit", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Log audit sistem", logs)
}

func (h *AdminHandler) GetStudentDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	student, err := h.paymentService.GetStudentDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
	}
	txs, _ := h.paymentService.ListStudentTransactions(c.Context(), id, 50)
	return response.Success(c, fiber.StatusOK, "Detail siswa", map[string]interface{}{
		"student":      student,
		"profile":      student.Profile,
		"transactions": txs,
	})
}

func (h *AdminHandler) GetMerchantDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	detail, err := h.paymentService.GetMerchantDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data stan / operator tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Detail operator stan", detail)
}

func (h *AdminHandler) GetParentDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	detail, err := h.paymentService.GetParentDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data orang tua tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Detail orang tua", detail)
}

func (h *AdminHandler) GetFinanceDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	detail, err := h.paymentService.GetFinanceOfficerDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data petugas keuangan tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Detail petugas keuangan", detail)
}

func (h *AdminHandler) ListFinanceOfficersLedger(c *fiber.Ctx) error {
	list, err := h.paymentService.ListFinanceOfficersLedger(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat rekap pembukuan petugas keuangan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Rekap pembukuan kas petugas keuangan", list)
}

func (h *AdminHandler) GetFinanceOfficerLedgerDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	detail, err := h.paymentService.GetFinanceOfficerLedgerDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Detail buku kas petugas keuangan tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Buku kas dan jurnal transaksi petugas keuangan", detail)
}

func (h *AdminHandler) GetAcademicStructure(c *fiber.Ctx) error {
	structData, err := h.catalogService.GetAcademicStructure(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat master struktur akademik", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Master struktur akademik sekolah", structData)
}

func (h *AdminHandler) SaveAcademicStructure(c *fiber.Ctx) error {
	var req domain.AcademicStructure
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format master struktur akademik tidak valid", err.Error())
	}

	if err := h.catalogService.SaveAcademicStructure(c.Context(), &req); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menyimpan master struktur akademik: "+err.Error(), err.Error())
	}

	if h.hub != nil {
		h.hub.BroadcastToRoom("all", "academic_structure_updated", req)
	}

	return response.Success(c, fiber.StatusOK, "Master struktur jenjang, jurusan, dan rombel sekolah berhasil disimpan", req)
}

func (h *AdminHandler) GetSettings(c *fiber.Ctx) error {
	settings, err := h.catalogService.GetGlobalSettings(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat setelan sistem", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Setelan sistem", settings)
}

func (h *AdminHandler) SaveSettings(c *fiber.Ctx) error {
	var req map[string]interface{}
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload setelan tidak valid", err.Error())
	}

	if err := h.catalogService.SaveGlobalSettings(c.Context(), req); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menyimpan setelan: "+err.Error(), err.Error())
	}

	if h.hub != nil {
		h.hub.BroadcastToRoom("all", "system_settings_updated", req)
	}

	return response.Success(c, fiber.StatusOK, "Setelan sistem berhasil disimpan", req)
}

type BroadcastRequest struct {
	Audience string `json:"audience"` // "all", "merchants", "students", "staff"
	Title    string `json:"title"`
	Message  string `json:"message"`
}

func (h *AdminHandler) Broadcast(c *fiber.Ctx) error {
	var req BroadcastRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload siaran tidak valid", err.Error())
	}

	req.Message = strings.TrimSpace(req.Message)
	if req.Message == "" {
		return response.Error(c, fiber.StatusBadRequest, "Isi pesan siaran pengumuman wajib diisi", nil)
	}

	title := strings.TrimSpace(req.Title)
	if title == "" {
		title = "Pengumuman Admin"
	}

	audience := strings.ToLower(strings.TrimSpace(req.Audience))
	if audience == "" {
		audience = "all"
	}

	count, err := h.catalogService.CreateBroadcastNotifications(c.Context(), audience, title, req.Message)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengirim siaran pengumuman: "+err.Error(), err.Error())
	}

	if h.hub != nil {
		notifPayload := fiber.Map{
			"title":      title,
			"message":    req.Message,
			"type":       "announcement",
			"audience":   audience,
			"created_at": time.Now(),
		}
		h.hub.BroadcastToRoom("all", "notification", notifPayload)
		h.hub.BroadcastToRoom("all", "notification:new", notifPayload)
		h.hub.BroadcastToRoom("all", "broadcast", notifPayload)
	}

	return response.Success(c, fiber.StatusOK, "Pesan siaran pengumuman berhasil dikirim", fiber.Map{
		"recipients": count,
		"audience":   audience,
	})
}
