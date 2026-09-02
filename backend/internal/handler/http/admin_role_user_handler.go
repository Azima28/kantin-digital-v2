package http

import (
	"errors"
	"strings"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/response"
)

var errEmptyFullName = errors.New("nama lengkap tidak boleh kosong")

// applyUserPatch overlays a partial update onto the profile that is currently
// stored and returns the result.
//
// Read-modify-write rather than writing the request straight through: every field
// of UpdateUserRequest is a pointer precisely so that a key the caller omitted
// keeps its stored value instead of being blanked by a zero value. The password
// hash is dropped from the copy so no update path can carry it back out in a
// response body.
func applyUserPatch(current *domain.UserProfile, req UpdateUserRequest) (*domain.UserProfile, error) {
	if current == nil {
		return nil, errors.New("pengguna tidak ditemukan")
	}
	merged := *current
	merged.Password = nil

	if req.FullName != nil {
		name := strings.TrimSpace(*req.FullName)
		if name == "" {
			return nil, errEmptyFullName
		}
		merged.FullName = name
	}
	if req.Email != nil {
		merged.Email = req.Email
	}
	if req.Username != nil {
		merged.Username = req.Username
	}
	if req.NISN != nil {
		merged.NISN = req.NISN
	}
	if req.PhoneNumber != nil {
		merged.PhoneNumber = req.PhoneNumber
	}
	if req.AvatarURL != nil {
		merged.AvatarURL = req.AvatarURL
	}
	if req.Relation != nil {
		merged.Relation = req.Relation
	}
	if req.Gender != nil {
		merged.Gender = req.Gender
	}
	if req.IsActive != nil {
		merged.IsActive = *req.IsActive
	}
	return &merged, nil
}

// updateRoleScopedUser is the shared body of the three role-specific edit routes.
//
// Each of them updates the profiles row the same way PUT /admin/users/:id does,
// and then writes the one or two fields that live in that role's own side table --
// which is why they cannot simply be pointed at UpdateUser. The role of the target
// is checked so the merchant route cannot be aimed at a finance officer and drag
// the wrong side-table write along with it.
//
// The two writes are separate statements against separate tables, so a failure in
// the second one is reported as a partial success. Claiming nothing happened would
// be a lie: the profile half has already landed by then.
func (h *AdminHandler) updateRoleScopedUser(
	c *fiber.Ctx,
	expected domain.Role,
	patch UpdateUserRequest,
	sideEffect func(target *domain.UserProfile) (fiber.Map, error),
) error {
	id := c.Params("id")

	claims := adminClaims(c)
	if claims == nil {
		return response.Error(c, fiber.StatusUnauthorized, "Autentikasi diperlukan", nil)
	}

	current, err := h.paymentService.GetUserByID(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Pengguna tidak ditemukan", err.Error())
	}
	if !strings.EqualFold(string(current.Role), string(expected)) {
		return response.Error(c, fiber.StatusBadRequest,
			"Endpoint ini hanya untuk peran "+string(expected)+", pengguna ini berperan "+string(current.Role), nil)
	}
	if err := authorizeUserMutation(claims.Role, claims.UserID, current, true); err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}

	merged, err := applyUserPatch(current, patch)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}
	merged.ID = id

	if err := h.paymentService.UpdateUser(c.Context(), merged); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui pengguna", err.Error())
	}

	data := fiber.Map{"user": merged}
	if sideEffect != nil {
		extra, sideErr := sideEffect(merged)
		if sideErr != nil {
			return response.Error(c, fiber.StatusInternalServerError,
				"Profil tersimpan, tetapi data khusus peran gagal diperbarui: "+sideErr.Error(), sideErr.Error())
		}
		for k, v := range extra {
			data[k] = v
		}
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "USER_UPDATED", "profiles", id,
		auditJSON(auditUserSnapshot(current)), auditJSON(auditUserSnapshot(merged)), c.IP())

	return response.Success(c, fiber.StatusOK, "Data pengguna berhasil diperbarui", data)
}

type UpdateCanteenOperatorRequest struct {
	UpdateUserRequest
	CanteenName *string `json:"canteen_name"`
}

// UpdateCanteenOperator backs PUT /admin/canteen-operators/:id.
//
// The admin app has been sending this request all along; the route did not exist,
// so the merchant edit sheet answered 404 and every edit made through it was
// silently discarded.
func (h *AdminHandler) UpdateCanteenOperator(c *fiber.Ctx) error {
	var req UpdateCanteenOperatorRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload update stan tidak valid", err.Error())
	}

	return h.updateRoleScopedUser(c, domain.RolePetugasKantin, req.UpdateUserRequest,
		func(target *domain.UserProfile) (fiber.Map, error) {
			if req.CanteenName == nil {
				return nil, nil
			}
			name := strings.TrimSpace(*req.CanteenName)
			if name == "" {
				return nil, errors.New("nama stan tidak boleh kosong")
			}
			if err := h.paymentService.UpdateCanteenOperatorProfile(c.Context(), target.ID, name); err != nil {
				return nil, err
			}
			return fiber.Map{"canteen_name": name}, nil
		})
}

type UpdateFinanceOfficerRequest struct {
	UpdateUserRequest
	AssignedSchool *string `json:"assigned_school"`
	AuthorityLevel *string `json:"authority_level"`
}

// UpdateFinanceOfficer backs PUT /admin/finance-officers/:id.
func (h *AdminHandler) UpdateFinanceOfficer(c *fiber.Ctx) error {
	var req UpdateFinanceOfficerRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload update petugas keuangan tidak valid", err.Error())
	}

	return h.updateRoleScopedUser(c, domain.RolePetugasKeuangan, req.UpdateUserRequest,
		func(target *domain.UserProfile) (fiber.Map, error) {
			if req.AssignedSchool == nil && req.AuthorityLevel == nil {
				return nil, nil
			}
			school := trimmedOrNil(req.AssignedSchool)
			level := trimmedOrNil(req.AuthorityLevel)
			if err := h.paymentService.UpdateFinanceOfficerProfile(c.Context(), target.ID, school, level); err != nil {
				return nil, err
			}
			extra := fiber.Map{}
			if school != nil {
				extra["assigned_school"] = *school
			}
			if level != nil {
				extra["authority_level"] = *level
			}
			return extra, nil
		})
}

type UpdateParentRequest struct {
	UpdateUserRequest
	LinkedNISNs []string `json:"linked_nisns"`
}

// UpdateParent backs PUT /admin/parents/:id.
//
// linked_nisns replaces the entire set of children attached to this parent, so an
// explicitly empty array unlinks all of them. A body that omits the key leaves the
// existing links untouched -- absent and empty are different requests, which is
// why the field is a slice tested for nil rather than for length.
//
// NISNs that match no student are reported back instead of failing the request:
// the profile edit itself succeeded, and the admin needs to see which numbers were
// mistyped rather than guess why nothing changed.
func (h *AdminHandler) UpdateParent(c *fiber.Ctx) error {
	var req UpdateParentRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload update orang tua tidak valid", err.Error())
	}

	return h.updateRoleScopedUser(c, domain.RoleParent, req.UpdateUserRequest,
		func(target *domain.UserProfile) (fiber.Map, error) {
			if req.LinkedNISNs == nil {
				return nil, nil
			}
			linked, missing, err := h.paymentService.SetParentLinkedStudents(c.Context(), target.ID, req.LinkedNISNs)
			if err != nil {
				return nil, err
			}
			return fiber.Map{
				"linked_students": linked,
				"missing_nisns":   missing,
			}, nil
		})
}

// trimmedOrNil keeps an omitted field omitted and treats a whitespace-only value
// as "no change" rather than as a request to store an empty string.
func trimmedOrNil(v *string) *string {
	if v == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*v)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}
