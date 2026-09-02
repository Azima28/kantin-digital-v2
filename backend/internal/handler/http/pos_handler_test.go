package http

import (
	"sync"
	"testing"
	"time"
)

// The scan session is the only proof that the student's card was physically
// present at the till. Without it a cashier could charge any student ID they
// could type. These tests pin the properties that make it proof: it is bound to
// one cashier, to one card, to one student, it expires, and it burns on use.

func resetScanSessions() {
	scanSessionLock.Lock()
	defer scanSessionLock.Unlock()
	scanSessions = make(map[string]scanSession)
}

func TestConsumeScanSessionIsSingleUse(t *testing.T) {
	resetScanSessions()
	rememberScanSession("op-1", "04:2A:B5:E2", "st-1")

	if !consumeScanSession("op-1", "04:2A:B5:E2", "st-1") {
		t.Fatal("pemindaian sah ditolak pada percobaan pertama")
	}
	if consumeScanSession("op-1", "04:2A:B5:E2", "st-1") {
		t.Error("pemindaian yang sama dapat dipakai dua kali (replay checkout)")
	}
}

func TestConsumeScanSessionWithoutAnyScanFails(t *testing.T) {
	resetScanSessions()
	if consumeScanSession("op-1", "04:2A:B5:E2", "st-1") {
		t.Error("checkout tanpa pemindaian kartu berhasil")
	}
}

func TestConsumeScanSessionRejectsSubstitutedStudent(t *testing.T) {
	resetScanSessions()
	rememberScanSession("op-1", "04:2A:B5:E2", "st-1")

	if consumeScanSession("op-1", "04:2A:B5:E2", "st-korban") {
		t.Error("kasir dapat membebankan pesanan ke siswa lain dengan kartu ini")
	}
	if consumeScanSession("op-1", "04:2A:B5:E2", "st-1") {
		t.Error("percobaan curang harus tetap membakar bukti pemindaian")
	}
}

func TestConsumeScanSessionIsBoundToTheScanningOperator(t *testing.T) {
	resetScanSessions()
	rememberScanSession("op-1", "04:2A:B5:E2", "st-1")

	if consumeScanSession("op-2", "04:2A:B5:E2", "st-1") {
		t.Error("kasir lain dapat memakai pemindaian milik kasir pertama")
	}
	if !consumeScanSession("op-1", "04:2A:B5:E2", "st-1") {
		t.Error("pemindaian milik kasir pertama seharusnya masih utuh")
	}
}

func TestConsumeScanSessionRejectsDifferentCard(t *testing.T) {
	resetScanSessions()
	rememberScanSession("op-1", "04:2A:B5:E2", "st-1")

	if consumeScanSession("op-1", "04:2A:B5:E3", "st-1") {
		t.Error("UID kartu yang berbeda diterima")
	}
}

func TestConsumeScanSessionAcceptsEquivalentUIDFormats(t *testing.T) {
	resetScanSessions()
	rememberScanSession("op-1", "04:2A:B5:E2", "st-1")

	// The reader hands over "04:2A:B5:E2"; the client may echo it unpunctuated
	// or lowercased. Same card, so the same proof.
	if !consumeScanSession("OP-1", " 04-2a-b5-e2 ", "ST-1") {
		t.Error("format UID/ID yang setara seharusnya dianggap sama")
	}
	if normalizeRFID("04:2A:B5:E2") != normalizeRFID("042ab5e2") {
		t.Error("normalisasi UID tidak konsisten")
	}
}

func TestConsumeScanSessionExpires(t *testing.T) {
	resetScanSessions()
	key := scanSessionKey("op-1", "04:2A:B5:E2")

	scanSessionLock.Lock()
	scanSessions[key] = scanSession{studentID: "st-1", scannedAt: time.Now().Add(-scanSessionTTL - time.Minute)}
	scanSessionLock.Unlock()

	if consumeScanSession("op-1", "04:2A:B5:E2", "st-1") {
		t.Error("pemindaian kedaluwarsa masih diterima")
	}
}

func TestRememberScanSessionPrunesExpiredEntries(t *testing.T) {
	resetScanSessions()

	scanSessionLock.Lock()
	scanSessions[scanSessionKey("op-lama", "AA:BB")] = scanSession{studentID: "st-lama", scannedAt: time.Now().Add(-scanSessionTTL - time.Hour)}
	scanSessionLock.Unlock()

	rememberScanSession("op-1", "04:2A:B5:E2", "st-1")

	scanSessionLock.Lock()
	_, stale := scanSessions[scanSessionKey("op-lama", "AA:BB")]
	total := len(scanSessions)
	scanSessionLock.Unlock()

	if stale {
		t.Error("entri kedaluwarsa tidak dibersihkan")
	}
	if total != 1 {
		t.Errorf("peta sesi seharusnya berisi 1 entri, dapat %d", total)
	}
}

// Two tills sharing one process must not corrupt the map.
func TestScanSessionsConcurrentAccess(t *testing.T) {
	resetScanSessions()

	var wg sync.WaitGroup
	for i := 0; i < 50; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			op := string(rune('a' + n%10))
			rememberScanSession(op, "04:2A:B5:E2", "st-1")
			consumeScanSession(op, "04:2A:B5:E2", "st-1")
		}(i)
	}
	wg.Wait()
}
