package http

import (
	"testing"
)

func TestValidateImageBytes(t *testing.T) {
	// Valid PNG header (8 bytes magic) + filler
	validPNG := []byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D}
	if err := validateImageBytes(validPNG, ".png"); err != nil {
		t.Errorf("Expected valid PNG to pass, got error: %v", err)
	}

	// Valid JPEG header
	validJPEG := []byte{0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01}
	if err := validateImageBytes(validJPEG, ".jpg"); err != nil {
		t.Errorf("Expected valid JPEG to pass, got error: %v", err)
	}

	// Valid WebP header: RIFF....WEBP
	validWebP := []byte{'R', 'I', 'F', 'F', 0x24, 0x00, 0x00, 0x00, 'W', 'E', 'B', 'P'}
	if err := validateImageBytes(validWebP, ".webp"); err != nil {
		t.Errorf("Expected valid WebP to pass, got error: %v", err)
	}

	// Malicious script masquerading as PNG
	fakePNG := []byte("<script>alert('xss')</script>")
	if err := validateImageBytes(fakePNG, ".png"); err == nil {
		t.Errorf("Expected fake PNG (HTML script) to fail validation, but it passed")
	}

	// Executable / ELF binary masquerading as JPEG
	fakeJPEG := []byte{0x7F, 'E', 'L', 'F', 0x02, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00}
	if err := validateImageBytes(fakeJPEG, ".jpg"); err == nil {
		t.Errorf("Expected binary executable as JPG to fail validation, but it passed")
	}

	// Empty / too small file
	tooSmall := []byte{0x89, 0x50}
	if err := validateImageBytes(tooSmall, ".png"); err == nil {
		t.Errorf("Expected too-small file to fail validation, but it passed")
	}
}
