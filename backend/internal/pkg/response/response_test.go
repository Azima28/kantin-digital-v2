package response

import (
	"encoding/json"
	"io"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
)

func TestResponseSuccess(t *testing.T) {
	app := fiber.New()
	app.Get("/test-success", func(c *fiber.Ctx) error {
		return Success(c, fiber.StatusOK, "Operasi berhasil", map[string]string{"foo": "bar"})
	})

	req := httptest.NewRequest("GET", "/test-success", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Failed to execute request: %v", err)
	}

	if resp.StatusCode != fiber.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	body, _ := io.ReadAll(resp.Body)
	var res Response
	if err := json.Unmarshal(body, &res); err != nil {
		t.Fatalf("Failed to parse response body: %v", err)
	}

	if !res.Success {
		t.Errorf("Expected success true, got false")
	}
	if res.Message != "Operasi berhasil" {
		t.Errorf("Expected message 'Operasi berhasil', got '%s'", res.Message)
	}
}

func TestResponseError(t *testing.T) {
	app := fiber.New()
	app.Get("/test-error", func(c *fiber.Ctx) error {
		return Error(c, fiber.StatusBadRequest, "Permintaan tidak valid", "detail error")
	})

	req := httptest.NewRequest("GET", "/test-error", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Failed to execute request: %v", err)
	}

	if resp.StatusCode != fiber.StatusBadRequest {
		t.Errorf("Expected status 400, got %d", resp.StatusCode)
	}

	body, _ := io.ReadAll(resp.Body)
	var res Response
	if err := json.Unmarshal(body, &res); err != nil {
		t.Fatalf("Failed to parse response body: %v", err)
	}

	if res.Success {
		t.Errorf("Expected success false, got true")
	}
}
