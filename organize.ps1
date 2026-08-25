# Run this from inside the Integriscanv2 folder
$folders = @("lib", "lib\theme", "lib\models", "lib\screens", "lib\widgets")
foreach ($f in $folders) {
    New-Item -ItemType Directory -Path $f -Force | Out-Null
}

$map = @{
    "main.dart" = "lib"
    "app_colors.dart" = "lib\theme"
    "theme_provider.dart" = "lib\theme"
    "scan_history_item.dart" = "lib\models"
    "education_topic.dart" = "lib\models"
    "main_shell.dart" = "lib\screens"
    "home_screen.dart" = "lib\screens"
    "progress_screen.dart" = "lib\screens"
    "clinic_locator_screen.dart" = "lib\screens"
    "discover_screen.dart" = "lib\screens"
    "account_screen.dart" = "lib\screens"
    "dashboard_header.dart" = "lib\widgets"
    "metrics_banner.dart" = "lib\widgets"
    "education_carousel.dart" = "lib\widgets"
    "custom_bottom_nav.dart" = "lib\widgets"
    "scan_action_sheet.dart" = "lib\widgets"
    "high_risk_banner.dart" = "lib\widgets"
}

foreach ($file in $map.Keys) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination $map[$file] -Force
        Write-Host "Moved $file -> $($map[$file])"
    } else {
        Write-Host "Skipped $file (not found, likely already moved)"
    }
}

Write-Host "`nDone. Run 'flutter pub get' next."