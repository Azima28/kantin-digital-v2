package http

import (
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
	"kantin-backend/internal/service"
)

// scanSessionTTL is how long a physical card read stays usable for a checkout.
// Long enough to ring up a full order, short enough that a UID captured earlier
// in the day is worthless.
const scanSessionTTL = 10 * time.Minute

type scanSession struct {
	studentID string
	scannedAt time.Time
}

// scanSessions is the proof that a card was actually tapped on this terminal.
//
// Checkout used to trust req.StudentID outright: any operator token plus a
// student UUID was enough to drain that student's balance, with no card and no
// student present. ScanCard writes an entry here, Checkout consumes it once, so a
// purchase now requires a card read that this same operator performed within the
// TTL. The map is process-local -- like orderPresenceMap in order_handler.go --
// which is fine for the single-instance deployment; a multi-replica rollout would
// need this moved into Postgres or Redis.
var (
	scanSessionLock sync.Mutex
	scanSessions    = make(map[string]scanSession)
)

// normalizeRFID strips the separators clients disagree about (04:2A:B5:E2 vs
// 042ab5e2) so a scan and its checkout always hash to the same key.
func normalizeRFID(uid string) string {
	replacer := strings.NewReplacer(":", "", "-", "", " ", "")
	return strings.ToLower(replacer.Replace(strings.TrimSpace(uid)))
}

func scanSessionKey(operatorID, rfidUID string) string {
	return strings.ToLower(strings.TrimSpace(operatorID)) + "|" + normalizeRFID(rfidUID)
}

func rememberScanSession(operatorID, rfidUID, studentID string) {
	key := scanSessionKey(operatorID, rfidUID)
	now := time.Now()

	scanSessionLock.Lock()
	defer scanSessionLock.Unlock()
	for k, s := range scanSessions {
		if now.Sub(s.scannedAt) > scanSessionTTL {
			delete(scanSessions, k)
		}
	}
	scanSessions[key] = scanSession{studentID: studentID, scannedAt: now}
}

// consumeScanSession verifies and burns the scan proof. Single use: a replayed
// checkout for the same tap finds nothing and is rejected.
func consumeScanSession(operatorID, rfidUID, studentID string) bool {
	key := scanSessionKey(operatorID, rfidUID)

	scanSessionLock.Lock()
	defer scanSessionLock.Unlock()
	session, ok := scanSessions[key]
	if !ok {
		return false
	}
	delete(scanSessions, key)
	if time.Since(session.scannedAt) > scanSessionTTL {
		return false
	}
	return strings.EqualFold(session.studentID, strings.TrimSpace(studentID))
}

type POSHandler struct {
	paymentService *service.PaymentService
}

func NewPOSHandler(paymentService *service.PaymentService) *POSHandler {
	return &POSHandler{paymentService: paymentService}
}

func (h *POSHandler) ScanCard(c *fiber.Ctx) error {
	rfid := c.Query("rfid", "")
	if rfid == "" {
		rfid = c.Query("uid", "")
	}
	if rfid == "" {
		return response.Error(c, fiber.StatusBadRequest, "Nomor UID RFID kartu wajib disertakan", nil)
	}

	student, err := h.paymentService.GetStudentByRFID(c.Context(), rfid)
	if err != nil || student == nil {
		return response.Error(c, fiber.StatusNotFound, "Kartu RFID tidak terdaftar pada akun siswa manapun atau sudah tidak berlaku", nil)
	}

	if !student.IsActive {
		return response.Error(c, fiber.StatusForbidden, "Kartu RFID ini sedang dinonaktifkan / dibekukan", nil)
	}
	if student.Profile != nil && !student.Profile.IsActive {
		return response.Error(c, fiber.StatusForbidden, "Akun siswa pemilik kartu ini sedang dinonaktifkan / diblokir", nil)
	}

	// Record that this operator physically read this card, so Checkout can insist
	// on it. The response shape is unchanged -- the client already keeps the UID it
	// scanned and now sends it back at checkout.
	if claims, ok := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims); ok && claims != nil {
		rememberScanSession(claims.UserID, rfid, student.ID)
	}

	return response.Success(c, fiber.StatusOK, "Data kartu siswa ditemukan", student)
}

type CheckoutRequest struct {
	StudentID string `json:"student_id"`
	// RfidUID is the card the operator just tapped. It is the proof of a physical
	// scan, not a lookup key -- the student is still identified by StudentID.
	RfidUID        string                   `json:"rfid_uid"`
	TotalAmount    int                      `json:"total_amount"`
	PurchaseMethod string                   `json:"purchase_method"`
	DeliveryLoc    string                   `json:"delivery_location"`
	Items          []domain.TransactionItem `json:"items"`
}

func (h *POSHandler) Checkout(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req CheckoutRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload checkout tidak valid", err.Error())
	}

	if req.StudentID == "" || req.TotalAmount <= 0 {
		return response.Error(c, fiber.StatusBadRequest, "Student ID dan total tagihan wajib valid", nil)
	}
	if req.RfidUID == "" {
		return response.Error(c, fiber.StatusBadRequest, "UID kartu RFID wajib disertakan: tempelkan kartu siswa terlebih dahulu", nil)
	}
	// Require -- and burn -- the scan this operator just performed. Without it a
	// stolen operator token plus a student ID was enough to spend someone's balance
	// while their card stayed in their pocket.
	if !consumeScanSession(claims.UserID, req.RfidUID, req.StudentID) {
		return response.Error(c, fiber.StatusForbidden,
			"Pemindaian kartu tidak valid atau sudah kedaluwarsa. Tempelkan kartu siswa kembali sebelum menyelesaikan pembayaran", nil)
	}

	params := postgres.CheckoutParams{
		StudentID:      req.StudentID,
		OperatorID:     claims.UserID,
		TotalAmount:    req.TotalAmount,
		PurchaseMethod: req.PurchaseMethod,
		DeliveryLoc:    req.DeliveryLoc,
		Items:          req.Items,
	}

	tx, err := h.paymentService.ProcessPurchase(c.Context(), params)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	return response.Success(c, fiber.StatusOK, "Pembayaran berhasil diproses", tx)
}

func (h *POSHandler) SalesHistory(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	limitStr := c.Query("limit", "100")
	limit, _ := strconv.Atoi(limitStr)

	operatorID := claims.UserID
	if (claims.Role == domain.RoleSuperAdmin || claims.Role == domain.RoleAdmin || claims.Role == domain.RolePetugasKeuangan) {
		if qOp := c.Query("operator_id"); qOp != "" {
			operatorID = qOp
		} else if qOff := c.Query("officer_id"); qOff != "" {
			operatorID = qOff
		}
	}

	transactions, err := h.paymentService.ListOperatorTransactions(c.Context(), operatorID, limit)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil riwayat transaksi", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Riwayat transaksi stan", transactions)
}

func (h *POSHandler) Activities(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	limitStr := c.Query("limit", "50")
	limit, _ := strconv.Atoi(limitStr)

	operatorID := claims.UserID
	if (claims.Role == domain.RoleSuperAdmin || claims.Role == domain.RoleAdmin || claims.Role == domain.RolePetugasKeuangan) {
		if qOp := c.Query("operator_id"); qOp != "" {
			operatorID = qOp
		} else if qOff := c.Query("officer_id"); qOff != "" {
			operatorID = qOff
		}
	}

	activities, err := h.paymentService.ListOperatorActivities(c.Context(), operatorID, limit)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil aktivitas stan", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Aktivitas stan kantin", activities)
}
