package hasher

import (
	"testing"
)

func TestHashPassword(t *testing.T) {
	password := "Secret123!"
	hash, err := HashPassword(password)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	if len(hash) == 0 {
		t.Fatalf("Expected non-empty hash string")
	}

	if hash == password {
		t.Fatalf("Hash should not be equal to plain password")
	}

	// Test valid comparison
	if !CheckPassword(password, hash) {
		t.Fatalf("Expected password check to return true for correct password")
	}

	// Test invalid password comparison
	if CheckPassword("WrongPassword", hash) {
		t.Fatalf("Expected password check to return false for incorrect password")
	}
}

// TestGenerateTempPassword is the regression test for the removed "password123"
// fallback: an account created without a password used to get a password that was
// printed in the login screen's demo panel, so knowing one account's password
// meant knowing every fresh account's password.
func TestGenerateTempPassword(t *testing.T) {
	const iterations = 200

	allowed := make(map[rune]bool, len(tempPasswordAlphabet))
	for _, r := range tempPasswordAlphabet {
		allowed[r] = true
	}

	seen := make(map[string]bool, iterations)
	for i := 0; i < iterations; i++ {
		pw, err := GenerateTempPassword()
		if err != nil {
			t.Fatalf("GenerateTempPassword gagal: %v", err)
		}
		if len(pw) != 12 {
			t.Fatalf("panjang kata sandi %d, mau 12: %q", len(pw), pw)
		}
		if pw == "password123" {
			t.Fatalf("kata sandi bawaan lama muncul kembali")
		}
		for _, r := range pw {
			if !allowed[r] {
				t.Fatalf("karakter di luar alfabet (%q) pada %q", r, pw)
			}
		}
		if seen[pw] {
			t.Fatalf("kata sandi terulang setelah %d percobaan (%q): entropinya tidak cukup", i+1, pw)
		}
		seen[pw] = true

		// The generated value must still be usable as a real credential. Only the
		// first couple of samples get hashed: bcrypt at DefaultCost costs about a
		// tenth of a second, and 200 of them would dominate the whole test run.
		if i < 2 {
			hash, hashErr := HashPassword(pw)
			if hashErr != nil {
				t.Fatalf("HashPassword gagal untuk kata sandi acak: %v", hashErr)
			}
			if !CheckPassword(pw, hash) {
				t.Fatalf("kata sandi acak tidak lolos verifikasinya sendiri")
			}
		}
	}

	// Characters that are easy to misread are excluded on purpose, because an
	// officer reads this password off the screen to hand it over.
	for _, bad := range []rune{'0', 'O', '1', 'l', 'I'} {
		if allowed[bad] {
			t.Errorf("alfabet masih memuat karakter ambigu %q", bad)
		}
	}
}
