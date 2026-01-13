$ErrorActionPreference = 'Stop'

$projectFile = $env:PS_PROJECT_FILE
$projectName = $env:PS_PROJECT_NAME

Write-Host "PowerShell received path: $projectFile"
Write-Host "PowerShell received name: $projectName"

if (-not (Test-Path -LiteralPath $projectFile)) {
    Write-Error "File not found: $projectFile"
    exit 1
}

try {
    $content = Get-Content -LiteralPath $projectFile -ErrorAction Stop
    $content = $content -replace '<name>FCM55S?.*?</name>', "<name>$projectName</name>"
    Set-Content -LiteralPath $projectFile -Value $content -ErrorAction Stop
    Write-Host "Successfully updated .project file"
    exit 0
} catch {
    Write-Error "Failed to update file: $_"
    exit 1
}
