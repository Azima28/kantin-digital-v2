package hasher

import (
	"crypto/rand"
	"math/big"

	"golang.org/x/crypto/bcrypt"
)

// tempPasswordAlphabet leaves out characters that are easy to misread when an
// officer reads a new account's password off the screen: 0/O, 1/l/I.
const tempPasswordAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"

// GenerateTempPassword returns a random 12-character password for an account that
// was created without one. It exists to replace a hard-coded "password123"
// fallback, which gave every such account the same publicly known password.
func GenerateTempPassword() (string, error) {
	limit := big.NewInt(int64(len(tempPasswordAlphabet)))
	buf := make([]byte, 12)
	for i := range buf {
		n, err := rand.Int(rand.Reader, limit)
		if err != nil {
			return "", err
		}
		buf[i] = tempPasswordAlphabet[n.Int64()]
	}
	return string(buf), nil
}

// HashPassword hashes plain text password using bcrypt
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

// CheckPassword checks plain password against bcrypt hashed password
func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
