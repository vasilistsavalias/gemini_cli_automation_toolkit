# Wrapper script to call the main Gemini setup script
param([string]$ProjectPath = $(Get-Location))

Write-Host "🚀 Setting up project in: $ProjectPath" -ForegroundColor Green

# Path to the main setup script (same folder)
$geminiScriptPath = Join-Path $PSScriptRoot "setup_gemini.ps1"

if (-Not (Test-Path $geminiScriptPath)) {
    Write-Error "❌ Gemini setup script not found at $geminiScriptPath"
    return
}

# Run the main setup script
try {
    Write-Host "⚡ Running Gemini setup..." -ForegroundColor Yellow
    
    # Use dot-sourcing or direct invocation instead of calling powershell.exe
    & $geminiScriptPath
    
    Write-Host "✅ Setup completed!" -ForegroundColor Green
} catch {
    Write-Error "❌ Error during setup: $($_.Exception.Message)"
}
