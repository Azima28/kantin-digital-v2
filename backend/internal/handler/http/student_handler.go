package http

import (
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/service"
)

type StudentHandler struct {
	paymentService *service.PaymentService
	notifService   *service.NotificationService
	tokenMaker     *token.TokenMaker
}

func NewStudentHandler(paymentService *service.PaymentService, notifService *service.NotificationService, tokenMaker *token.TokenMaker) *StudentHandler {
	return &StudentHandler{
		paymentService: paymentService,
		notifService:   notifService,
		tokenMaker:     tokenMaker,
	}
}

type PublicStudentProfile struct {
	ID        string  `json:"id"`
	FullName  string  `json:"full_name"`
	Class     string  `json:"class"`
	Rombel    string  `json:"rombel"`
	NISN      *string `json:"nisn,omitempty"`
	AvatarURL *string `json:"avatar_url,omitempty"`
}

func (h *StudentHandler) LookupStudent(c *fiber.Ctx) error {
	nisn := c.Query("nisn", "")
	if nisn == "" {
		nisn = c.Query("nis", "")
	}

	// 1. If querying by NISN (public parent portal lookup)
	if nisn != "" {
		student, err := h.paymentService.GetStudentByNISN(c.Context(), nisn)
		if err != nil {
			return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
		}
		fullName := "Siswa"
		var avatarURL *string
		var nisnPtr *string
		if student.Profile != nil {
			fullName = student.Profile.FullName
			avatarURL = student.Profile.AvatarURL
			nisnPtr = student.Profile.NISN
		}
		publicProfile := PublicStudentProfile{
			ID:        student.ID,
			FullName:  fullName,
			Class:     student.Class,
			Rombel:    student.Rombel,
			NISN:      nisnPtr,
			AvatarURL: avatarURL,
		}
		return response.Success(c, fiber.StatusOK, "Data siswa ditemukan", publicProfile)
	}

	// 2. For ID queries or search / list queries, authentication is mandatory
	tokenStr := c.Get("Authorization")
	if len(tokenStr) > 7 && strings.HasPrefix(tokenStr, "Bearer ") {
		tokenStr = tokenStr[7:]
	} else {
		tokenStr = c.Cookies("access_token")
	}

	if tokenStr == "" {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan untuk mencari atau mengakses data siswa", nil)
	}

	claims, err := h.tokenMaker.VerifyToken(tokenStr)
	if err != nil || claims == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Token autentikasi tidak valid atau telah kedaluwarsa", nil)
	}

	studentID := c.Query("id", "")
	if studentID == "" {
		studentID = c.Query("student_id", "")
	}

	// If lookup by ID
	if studentID != "" {
		// Authorization check for ID lookup:
		// Allowed: super_admin, admin, petugas_keuangan, petugas_kantin
		// If student: only their own ID
		// If parent: only their linked children
		switch claims.Role {
		case domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan, domain.RolePetugasKantin:
			// Allowed
		case domain.RoleStudent:
			if claims.UserID != studentID {
				return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Anda hanya dapat melihat profil akun Anda sendiri", nil)
			}
		case domain.RoleParent:
			children, err := h.paymentService.GetParentChildren(c.Context(), claims.UserID)
			if err != nil {
				return response.Error(c, fiber.StatusInternalServerError, "Gagal memverifikasi relasi anak", err.Error())
			}
			isLinked := false
			for _, child := range children {
				if child.ID == studentID {
					isLinked = true
					break
				}
			}
			if !isLinked {
				return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Anda tidak memiliki akses ke siswa ini", nil)
			}
		default:
			return response.Error(c, fiber.StatusForbidden, "Akses ditolak", nil)
		}

		student, err := h.paymentService.GetStudentDetail(c.Context(), studentID)
		if err != nil {
			return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
		}
		return response.Success(c, fiber.StatusOK, "Data detail siswa ditemukan", student)
	}

	// Search or Full List lookup
	// Only authorized staff (finance, cashier, admin) can search across all students
	if claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RoleAdmin && claims.Role != domain.RolePetugasKeuangan && claims.Role != domain.RolePetugasKantin {
		return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Hanya petugas atau staf yang berwenang mencari data siswa", nil)
	}

	search := c.Query("search", "")
	if search == "" {
		search = c.Query("q", "")
	}

	students, err := h.paymentService.SearchStudents(c.Context(), search)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mencari data siswa", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Hasil pencarian siswa", students)
}

func (h *StudentHandler) GetMyProfile(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	student, err := h.paymentService.GetStudentDetail(c.Context(), claims.UserID)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Profil siswa", student)
}

func (h *StudentHandler) GetTransactions(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	targetStudentID := ""
	if claims.Role == domain.RoleStudent {
		targetStudentID = claims.UserID
	} else if claims.Role == domain.RolePetugasKantin {
		if c.Query("student_id") != "" {
			targetStudentID = c.Query("student_id")
		}
	} else {
		// SuperAdmin, Admin, PetugasKeuangan
		targetStudentID = c.Query("student_id", "")
	}

	operatorID := c.Query("operator_id", "")
	if claims.Role == domain.RolePetugasKantin && operatorID == "" {
		operatorID = claims.UserID
	}

	limitStr := c.Query("limit", "100")
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 {
		limit = 100
	}

	pageStr := c.Query("page", "1")
	page, _ := strconv.Atoi(pageStr)
	if page <= 0 {
		page = 1
	}

	offsetStr := c.Query("offset", "")
	var offset int
	if offsetStr != "" {
		offset, _ = strconv.Atoi(offsetStr)
	} else {
		offset = (page - 1) * limit
	}

	txType := c.Query("type", "")
	status := c.Query("status", "")
	search := c.Query("search", "")

	txs, total, err := h.paymentService.ListStudentTransactionsPaged(c.Context(), targetStudentID, operatorID, limit, offset, txType, status, search)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil riwayat", err.Error())
	}

	hasMore := (offset + len(txs)) < total

	return response.Success(c, fiber.StatusOK, "Riwayat transaksi siswa", fiber.Map{
		"items":    txs,
		"total":    total,
		"limit":    limit,
		"offset":   offset,
		"page":     page,
		"has_more": hasMore,
	})
}

func (h *StudentHandler) GetNotifications(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	limitStr := c.Query("limit", "50")
	limit, _ := strconv.Atoi(limitStr)

	notifs, err := h.notifService.ListByStudent(c.Context(), claims.UserID, limit)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil notifikasi", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Notifikasi siswa", notifs)
}

func (h *StudentHandler) MarkNotificationRead(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	notifID := c.Params("id")

	if err := h.notifService.MarkAsRead(c.Context(), notifID, claims.UserID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui notifikasi", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Notifikasi ditandai dibaca", nil)
}

func (h *StudentHandler) MarkAllNotificationsRead(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	if err := h.notifService.MarkAllAsRead(c.Context(), claims.UserID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui notifikasi", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Semua notifikasi ditandai dibaca", nil)
}

func (h *StudentHandler) DeleteNotification(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	notifID := c.Params("id")
	if notifID == "" {
		return response.Error(c, fiber.StatusBadRequest, "ID notifikasi wajib diisi", nil)
	}

	if err := h.notifService.Delete(c.Context(), notifID, claims.UserID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menghapus notifikasi", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Notifikasi berhasil dihapus", nil)
}

func (h *StudentHandler) DeleteAllNotifications(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	if err := h.notifService.DeleteAll(c.Context(), claims.UserID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menghapus semua notifikasi", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Semua notifikasi berhasil dihapus", nil)
}


type UpdateCardStatusRequest struct {
	StudentID string  `json:"student_id"`
	RfidUID   *string `json:"rfid_uid"`
	IsActive  *bool   `json:"is_active"`
}

func (h *StudentHandler) UpdateCardStatus(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req UpdateCardStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}
	if req.StudentID == "" {
		return response.Error(c, fiber.StatusBadRequest, "Student ID wajib diisi", nil)
	}

	// Authorization & IDOR protection:
	switch claims.Role {
	case domain.RoleStudent:
		if claims.UserID != req.StudentID {
			return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Siswa hanya dapat mengelola kartu miliknya sendiri", nil)
		}
		// Siswa tidak diizinkan mengubah RFID UID fisik, hanya membekukan/mengaktifkan
		req.RfidUID = nil
	case domain.RoleParent:
		children, err := h.paymentService.GetParentChildren(c.Context(), claims.UserID)
		if err != nil {
			return response.Error(c, fiber.StatusInternalServerError, "Gagal memverifikasi relasi anak", err.Error())
		}
		isLinked := false
		for _, child := range children {
			if child.ID == req.StudentID {
				isLinked = true
				break
			}
		}
		if !isLinked {
			return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Anda tidak memiliki akses ke kartu siswa ini", nil)
		}
		// Orang tua tidak diizinkan mengubah RFID UID fisik, hanya membekukan/mengaktifkan
		req.RfidUID = nil
	case domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin:
		// Petugas berwenang penuh
	default:
		return response.Error(c, fiber.StatusForbidden, "Akses ditolak", nil)
	}

	if err := h.paymentService.UpdateStudentCardStatus(c.Context(), req.StudentID, req.RfidUID, req.IsActive); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui status kartu: "+err.Error(), err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Status kartu berhasil diperbarui", nil)
}

type StudentTopupRequest struct {
	StudentID     string  `json:"student_id"`
	Amount        int     `json:"amount"`
	PaymentMethod *string `json:"payment_method"`
}

func (h *StudentHandler) Topup(c *fiber.Ctx) error {
	claimsVal := c.Locals(middleware.UserClaimsKey)
	if claimsVal == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}
	claims := claimsVal.(*token.JWTClaims)

	var req StudentTopupRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload top-up tidak valid", err.Error())
	}

	targetStudentID := req.StudentID
	switch claims.Role {
	case domain.RoleStudent:
		// Student top-up is processed automatically via QRIS/instant settlement
		targetStudentID = claims.UserID
	case domain.RoleParent:
		// Parent can only top up their linked child
		if targetStudentID == "" {
			return response.Error(c, fiber.StatusBadRequest, "Student ID wajib disertakan", nil)
		}
		children, err := h.paymentService.GetParentChildren(c.Context(), claims.UserID)
		if err != nil {
			return response.Error(c, fiber.StatusInternalServerError, "Gagal memverifikasi relasi anak", err.Error())
		}
		isLinked := false
		for _, child := range children {
			if child.ID == targetStudentID {
				isLinked = true
				break
			}
		}
		if !isLinked {
			return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Anda tidak memiliki akses ke siswa ini", nil)
		}
	case domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin:
		if targetStudentID == "" {
			return response.Error(c, fiber.StatusBadRequest, "Student ID wajib disertakan", nil)
		}
	default:
		return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Peran Anda tidak memiliki wewenang melakukan top-up", nil)
	}

	if req.Amount < 10000 {
		return response.Error(c, fiber.StatusBadRequest, "Nominal top-up minimal Rp 10.000", nil)
	}
	if req.Amount > 2000000 {
		return response.Error(c, fiber.StatusBadRequest, "Nominal top-up maksimal Rp 2.000.000 per transaksi", nil)
	}

	method := "qris"
	if claims.Role == domain.RolePetugasKeuangan || claims.Role == domain.RoleSuperAdmin || claims.Role == domain.RoleAdmin {
		method = "cash"
	}
	if req.PaymentMethod != nil && *req.PaymentMethod != "" {
		method = *req.PaymentMethod
	}

	tx, err := h.paymentService.ProcessTopupWithMethod(c.Context(), targetStudentID, claims.UserID, req.Amount, method)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	actorName := claims.Email
	if claims.FullName != "" {
		actorName = claims.FullName
	}
	studentName := ""
	if tx.StudentName != nil {
		studentName = *tx.StudentName
	}
	balBefore := 0
	if tx.BalanceBefore != nil {
		balBefore = *tx.BalanceBefore
	}
	balAfter := balBefore + req.Amount
	if tx.BalanceAfter != nil {
		balAfter = *tx.BalanceAfter
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "STUDENT_TOPUP", "students", targetStudentID,
		auditJSON(map[string]interface{}{
			"balance":        balBefore,
			"balance_before": balBefore,
			"status":         "Aktif",
		}),
		auditJSON(map[string]interface{}{
			"amount":         req.Amount,
			"total_amount":   req.Amount,
			"balance":        balAfter,
			"balance_before": balBefore,
			"balance_after":  balAfter,
			"transaction_id": tx.ID,
			"actor_role":     claims.Role,
			"actor_name":     actorName,
			"student_name":   studentName,
			"method":         method,
			"status":         "Sukses",
		}), c.IP())

	return response.Success(c, fiber.StatusOK, "Top-up saldo berhasil diproses", tx)
}

type StudentChangePinRequest struct {
	OldPin string `json:"old_pin"`
	NewPin string `json:"new_pin"`
}

func (h *StudentHandler) ChangePin(c *fiber.Ctx) error {
	claimsVal := c.Locals(middleware.UserClaimsKey)
	if claimsVal == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}
	claims := claimsVal.(*token.JWTClaims)

	var req StudentChangePinRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}

	targetStudentID := claims.UserID
	if claims.Role != domain.RoleStudent {
		if sID := c.Query("student_id"); sID != "" {
			targetStudentID = sID
		}
	}

	if err := h.paymentService.StudentChangePin(c.Context(), targetStudentID, req.OldPin, req.NewPin); err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "STUDENT_PIN_CHANGED", "students", targetStudentID,
		"",
		auditJSON(map[string]interface{}{
			"status": "PIN Transaksi Diperbarui",
		}), c.IP())

	return response.Success(c, fiber.StatusOK, "PIN transaksi berhasil diperbarui", nil)
}

type VerifyPinRequest struct {
	Pin       string `json:"pin"`
	StudentID string `json:"student_id"`
}

func (h *StudentHandler) VerifyPin(c *fiber.Ctx) error {
	claimsVal := c.Locals(middleware.UserClaimsKey)
	if claimsVal == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}
	claims := claimsVal.(*token.JWTClaims)

	var req VerifyPinRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}

	targetStudentID := claims.UserID
	if req.StudentID != "" && (claims.Role == domain.RoleSuperAdmin || claims.Role == domain.RoleAdmin || claims.Role == domain.RolePetugasKeuangan || claims.Role == domain.RolePetugasKantin) {
		targetStudentID = req.StudentID
	}

	valid, err := h.paymentService.VerifyStudentPin(c.Context(), targetStudentID, req.Pin)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	if !valid {
		return response.Error(c, fiber.StatusBadRequest, "PIN transaksi salah. Silakan coba lagi.", fiber.Map{"valid": false})
	}

	return response.Success(c, fiber.StatusOK, "PIN transaksi benar", fiber.Map{"valid": true})
}
