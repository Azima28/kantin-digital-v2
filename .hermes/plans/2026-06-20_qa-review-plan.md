# QA Review Plan — Kantin Digital

> **Execution:** Parallel subagent batches + sequential review pipeline

**Goal:** Run comprehensive QA on Kantin Digital using `requesting-code-review` (code review) and `dogfood` (exploratory QA).

**Current State:** flutter analyze = 0 production errors. 37+ commits of changes.

---

## Phase 1 — `requesting-code-review` (Code Review Pipeline)

### Overview
Systematic pre-commit verification using the skill's pipeline:
1. Static security scan
2. Baseline linting
3. Independent reviewer subagent
4. Auto-fix loop (if needed)
5. Final commit

### Scope
Review ALL changed files since the original clone (37+ commits). Because the full diff is massive, we split by feature area:

### Batch 1a — Core Models & Providers Review (3 agents parallel)

**Agent 1:** Review ALL model files (`lib/core/models/*.dart`)
- Security scan: password field exposure, toJson sends password?
- Logic check: fromJson/toJson balance, nullable fields, type safety
- Static scan: hardcoded secrets, injection risks

**Agent 2:** Review ALL provider files (`lib/features/*/providers/*.dart` + `lib/core/providers/*.dart`)
- Security: RPC calls, direct DB mutations, auth bypass
- Logic: error handling, invalidation chains, family params
- Static scan: debug leaks, hardcoded credentials

**Agent 3:** Review ALL route + service files (`lib/core/router/*.dart`, `lib/core/services/*.dart`)
- Security: route guards, auth_service password handling, token storage
- Logic: redirect logic, error handling in services

### Batch 1b — Screen & Widget Review (3 agents parallel)

**Agent 1:** Review admin + auth screens (`lib/features/admin/`, `lib/features/auth/`)
- Security: secure_entry PIN, admin routes, password changes
- Logic: form validation, state handling, data display

**Agent 2:** Review keuangan + parent screens (`lib/features/keuangan/`, `lib/features/parent/`)
- Logic: financial calculations, topup flow, balance display
- Static scan: hardcoded values, error message quality

**Agent 3:** Review kantin + siswa + public + shared screens
- Logic: cart behavior, NFC flow, product management
- Static scan: price manipulation, double-tap risks

### Batch 1c — Theme & Constants Review (1 agent)
- `lib/core/constants/`, `lib/core/theme/`
- Consistency: color usage, string usage, font usage
- Dead code: unused constants

### Auto-Fix Loop
After each batch:
1. Collect all findings from the 3 agents
2. If any CRITICAL/HIGH findings → spawn auto-fix agent
3. Re-run flutter analyze
4. Max 2 fix cycles per batch

### Final Verification
```
flutter analyze
flutter test (if any tests exist)
git diff --stat
```

---

## Phase 2 — `dogfood` (Exploratory QA via Browser)

### Challenge
Kantin Digital is a **Flutter mobile app**, not a web app. `dogfood` is designed for browser-based web apps.

### Approach — Flutter Web Build
Build the Flutter app as web, then use browser tools for QA:

```
cd ~/projects/kantin-digital
flutter build web --release
cd build/web
python -m http.server 8080
```

Then use `dogfood` skill to:
1. Navigate to `http://localhost:8080`
2. Test all routes and features via browser
3. Capture screenshots of issues
4. Generate bug report

### Test Plan (5 phases per dogfood skill):

**Phase 1: Auth Flow**
- Login screen: test all 5 credential presets
- Test invalid credentials → error message
- Test empty fields → validation
- Check console for JS errors

**Phase 2: Admin Dashboard**
- Navigate all admin routes
- Test user management (create, toggle status)
- Test settings page
- Check data display

**Phase 3: Keuangan (Finance)**
- Student list and search
- Topup flow
- Correction flow
- Reports page

**Phase 4: POS/Kantin**
- Product management
- Cart functionality
- Order list
- Sales history

**Phase 5: Parent & Siswa**
- Parent portal (student lookup)
- Parent dashboard
- Siswa dashboard
- Notifications

### Evidence Collection
Per dogfood skill:
- `browser_vision()` screenshots for each issue
- `browser_console()` after each interaction
- Structured bug report with severity classification

### Limitation
Flutter web may differ from mobile behavior (no NFC, no camera). Mark NFC-dependent features as "not testable via web" in the report.

---

## Execution Flow

```
Phase 1 ─┬─ Batch 1a: Models + Providers + Routes (3 agents)
          ├─ Auto-fix if needed
          ├─ Batch 1b: Screens + Widgets (3 agents)
          ├─ Auto-fix if needed  
          ├─ Batch 1c: Theme + Constants (1 agent)
          ├─ Auto-fix if needed
          └─ Final flutter analyze verify
               ↓
Phase 2 ─┬─ flutter build web
          ├─ python http.server
          ├─ Dogfood QA (5 phases)
          └─ Bug report generation
               ↓
         PRESENT RESULTS
```

## Timeline Estimate
- Phase 1: ~3-5 batch cycles (depends on findings)
- Phase 2: ~1-2 batch cycles (browser testing is slower)

## Risks
1. Flutter web build may have platform-specific bugs not relevant to mobile
2. NFC/camera features untestable in browser
3. Supabase might block browser requests (CORS)
4. Large diff = many review findings = many cycles
