import re

# 1. Clean main.go
with open('backend/cmd/api/main.go', 'r', encoding='utf-8') as f:
    main_lines = f.readlines()

new_main_lines = [l for l in main_lines if '/correction' not in l and '/merchant/adjust' not in l]

with open('backend/cmd/api/main.go', 'w', encoding='utf-8') as f:
    f.writelines(new_main_lines)
print('1. main.go cleaned')

# 2. Clean payment_service.go
with open('backend/internal/service/payment_service.go', 'r', encoding='utf-8') as f:
    ps_content = f.read()

# Remove ProcessCorrection and ProcessMerchantAdjustment from payment_service.go
ps_content = re.sub(r'func \(s \*PaymentService\) ProcessCorrection\([^)]*\)[^{]*\{[\s\S]*?\n\}\n', '', ps_content)
ps_content = re.sub(r'func \(s \*PaymentService\) ProcessMerchantAdjustment\([^)]*\)[^{]*\{[\s\S]*?\n\}\n', '', ps_content)

with open('backend/internal/service/payment_service.go', 'w', encoding='utf-8') as f:
    f.write(ps_content)
print('2. payment_service.go cleaned')

# 3. Clean transaction_repo.go
with open('backend/internal/repository/postgres/transaction_repo.go', 'r', encoding='utf-8') as f:
    tr_content = f.read()

tr_content = re.sub(r'func \(r \*TransactionRepo\) ProcessCorrection\([^)]*\)[^{]*\{[\s\S]*?\n\}\n', '', tr_content)
tr_content = re.sub(r'func \(r \*TransactionRepo\) ProcessMerchantAdjustment\([^)]*\)[^{]*\{[\s\S]*?\n\}\n', '', tr_content)

# In FinanceSummary struct
tr_content = re.sub(r'KoreksiTodayCount\s+int\s+`json:"koreksi_today_count"`\n', '', tr_content)
tr_content = re.sub(r'KoreksiTodayNet\s+int\s+`json:"koreksi_today_net"`\n', '', tr_content)

# In GetFinanceDashboardSummary query 3 (Corrections today)
tr_content = re.sub(r'// 3\. Corrections today[\s\S]*?Scan\(&s\.KoreksiTodayCount, &s\.KoreksiTodayNet\)\n', '', tr_content)

# In GetFinanceReport
tr_content = re.sub(r'// 3\. Corrections net amount in range[\s\S]*?Scan\(&rep\.TotalCorrection\)\n', '', tr_content)
tr_content = re.sub(r'TotalCorrection\s+int\s+`json:"total_correction"`\n', '', tr_content)

with open('backend/internal/repository/postgres/transaction_repo.go', 'w', encoding='utf-8') as f:
    f.write(tr_content)
print('3. transaction_repo.go cleaned')

# 4. Clean transaction.go (domain)
with open('backend/internal/domain/transaction.go', 'r', encoding='utf-8') as f:
    dom_content = f.read()

dom_content = dom_content.replace('TxTypeCorrection         TransactionType = "correction"\n', '')
dom_content = dom_content.replace('TxTypeMerchantAdjustment TransactionType = "merchant_adjustment"\n', '')

with open('backend/internal/domain/transaction.go', 'w', encoding='utf-8') as f:
    f.write(dom_content)
print('4. domain/transaction.go cleaned')
