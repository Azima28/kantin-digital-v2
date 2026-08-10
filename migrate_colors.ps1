$baseDir = "D:\Kantin-Digital-v2\kantin-digital-v2\lib\features"
$nebulaImport = "import 'package:kantin_digital/core/theme/nebula_colors.dart';"
$appColorsImport = [regex]::Escape("import 'package:kantin_digital/core/constants/app_colors.dart';")

$files = @(
    "parent\widgets\midtrans_cstore_detail_form.dart",
    "parent\widgets\midtrans_payment_method_item.dart",
    "parent\widgets\midtrans_va_detail_form.dart",
    "parent\widgets\parent_action_grid.dart",
    "parent\widgets\parent_amount_selector.dart",
    "parent\widgets\parent_analisis_period_selector.dart",
    "parent\widgets\parent_balance_card.dart",
    "parent\widgets\parent_category_breakdown.dart",
    "parent\widgets\parent_dashboard_header.dart",
    "parent\widgets\parent_favorite_products.dart",
    "parent\widgets\parent_home_tab.dart",
    "parent\widgets\parent_midtrans_payment_modal.dart",
    "parent\widgets\parent_receipt_bottom_sheet.dart",
    "parent\widgets\parent_settings_section.dart",
    "parent\widgets\parent_topup_form.dart",
    "parent\widgets\parent_transaction_list.dart",
    "parent\widgets\parent_transaction_tile.dart",
    "parent\widgets\parent_weekly_trend_chart.dart",
    "siswa\widgets\qris_checkout_content.dart",
    "siswa\widgets\siswa_change_password_panel.dart",
    "siswa\widgets\siswa_freeze_card_dialog.dart",
    "siswa\widgets\siswa_main_layout.dart",
    "siswa\widgets\siswa_payment_animation_overlay.dart",
    "siswa\widgets\siswa_profile_header.dart",
    "siswa\widgets\siswa_quick_amount_item.dart",
    "siswa\widgets\siswa_transaction_detail_sheet.dart",
    "siswa\widgets\topup_payment_info_card.dart",
    "siswa\widgets\topup_qris_checkout_sheet.dart",
    "auth\widgets\login_account_preview.dart",
    "auth\widgets\login_preview_item.dart",
    "auth\widgets\role_toggle_button.dart"
)

$replacements = @(
    @{old = 'AppColors.primaryLight'; new = 'Nebula.teal.withValues(alpha: 0.08)'}
    @{old = 'AppColors.errorRed2';    new = 'Nebula.rose'}
    @{old = 'AppColors.successGreen'; new = 'Nebula.teal'}
    @{old = 'AppColors.darkTeal';     new = 'Nebula.teal'}
    @{old = 'AppColors.textPrimary';  new = 'Starlight.bright'}
    @{old = 'AppColors.textSecondary'; new = 'Starlight.dim'}
    @{old = 'AppColors.borderLight';  new = "Starlight.dim.withValues(alpha: 0.3)"}
    @{old = 'AppColors.softOrange';   new = "Nebula.amber.withValues(alpha: 0.3)"}
    @{old = 'AppColors.softTeal';     new = "Nebula.teal.withValues(alpha: 0.2)"}
    @{old = 'AppColors.accentOrange'; new = 'Nebula.amber'}
    @{old = 'AppColors.darkOrange';   new = 'Nebula.amber'}
    @{old = 'AppColors.textDark';     new = 'Starlight.bright'}
    @{old = 'AppColors.textGray';     new = 'Starlight.dim'}
    @{old = 'AppColors.darkGray';     new = 'Starlight.dim'}
    @{old = 'AppColors.borderGray';   new = "Starlight.dim.withValues(alpha: 0.3)"}
    @{old = 'AppColors.mutedGray';    new = 'Starlight.dim'}
    @{old = 'AppColors.lightGray';    new = "Starlight.dim.withValues(alpha: 0.5)"}
    @{old = 'AppColors.cardBackground'; new = 'Cosmic.surface'}
    @{old = 'AppColors.white';        new = 'Colors.white'}
    @{old = 'AppColors.primary';      new = 'Nebula.teal'}
    @{old = 'AppColors.error';        new = 'Nebula.rose'}
    @{old = 'AppColors.success';      new = 'Nebula.teal'}
    @{old = 'AppColors.teal';         new = 'Nebula.teal'}
)

$total = $files.Count
$current = 0

foreach ($relPath in $files) {
    $current++
    $fullPath = Join-Path $baseDir $relPath
    Write-Host "[$current/$total] $relPath"

    $content = Get-Content $fullPath -Raw

    if (-not $content) {
        Write-Warning "  Empty file: $relPath"
        continue
    }

    # 1) Add nebula_colors.dart import if not already present
    if ($content -notmatch [regex]::Escape($nebulaImport)) {
        $lines = $content -split "(?<=\n)"
        $lastImportIdx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*import ') {
                $lastImportIdx = $i
            }
        }
        if ($lastImportIdx -ge 0) {
            # Insert nebula import after the last import line
            $lines = $lines[0..$lastImportIdx] + @($nebulaImport + "`n") + $lines[($lastImportIdx+1)..($lines.Count-1)]
            $content = $lines -join ""
        }
    }

    # 2) Apply all color replacements
    foreach ($r in $replacements) {
        $escapedOld = [regex]::Escape($r.old)
        $content = $content -replace $escapedOld, $r.new
    }

    # 3) Remove app_colors.dart import if AppColors no longer used
    if ($content -notmatch '\bAppColors\b') {
        $content = $content -replace "$appColorsImport`r?`n", ""
        $content = $content -replace "$appColorsImport", ""
    }

    # Write back
    [System.IO.File]::WriteAllText($fullPath, $content, [System.Text.UTF8Encoding]::new($false))
}

Write-Host "`nDone! $total files processed."
