$ErrorActionPreference = 'Stop'

$bswBat = $env:PS_BSW_BAT
$projectName = $env:PS_PROJECT_NAME

Write-Host "PowerShell received path: $bswBat"
Write-Host "PowerShell received name: $projectName"

if (-not (Test-Path -LiteralPath $bswBat)) {
    Write-Error "File not found: $bswBat"
    exit 1
}

try {
    $content = Get-Content -LiteralPath $bswBat -ErrorAction Stop
    # Replace PROJECT_NAME value while preserving surrounding quotes and structure
    $content = $content -replace '(PROJECT_NAME=)[^"]+', "`$1$projectName"
    Set-Content -LiteralPath $bswBat -Value $content -ErrorAction Stop
    Write-Host "Successfully updated BswDevStart_r2.bat file"
    exit 0
} catch {
    Write-Error "Failed to update file: $_"
    exit 1
}
