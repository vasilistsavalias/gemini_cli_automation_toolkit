<#
.SYNOPSIS
Automates upgrading Node.js (to ≥ 20.18.1), updating npm, and installing Google Gemini CLI globally.
.DESCRIPTION
1. Checks for Administrator rights.
2. Verifies Node.js version; if < 20.18.1, upgrades via Chocolatey or MSI installer.
3. Updates npm to latest.
4. Installs @google/gemini-cli globally.
5. Verifies installation and logs progress/errors.
#>

# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error "[ERROR] Administrator privileges required. Please re-run this script as Administrator."
    exit 1
}

# Utility: compare semantic versions
function Test-Version {
    param(
        [Parameter(Mandatory)] [string] $Current,
        [Parameter(Mandatory)] [string] $Required
    )
    try {
        return ([version]$Current) -ge ([version]$Required)
    } catch {
        return $false
    }
}

$requiredNode = '20.18.1'

# Step 1: Check Node.js installation and version
Write-Host "[INFO] Checking Node.js installation..."
try {
    $nodeVer = (node --version).TrimStart('v')
    Write-Host "[INFO] Current Node.js version: $nodeVer"
} catch {
    Write-Warning "[WARN] Node.js not found. Will install latest LTS."
    $nodeVer = "0.0.0"
}

# Step 2: Upgrade Node.js if needed
if (-not (Test-Version -Current $nodeVer -Required $requiredNode)) {
    Write-Host "[INFO] Node.js version is below $requiredNode. Upgrading..."
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "[INFO] Installing Node.js LTS via Chocolatey..."
        choco install nodejs-lts -y | Out-Host
    } else {
        Write-Host "[INFO] Chocolatey not found. Downloading Node.js installer..."
        $msiUrl = "https://nodejs.org/dist/v$requiredNode/node-v$requiredNode-x64.msi"
        $msiPath = Join-Path $env:TEMP "node-v$requiredNode-x64.msi"
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath
        Write-Host "[INFO] Running Node.js MSI installer silently..."
        Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait
        Remove-Item $msiPath -Force
    }
    # Refresh environment for node
    & refreshenv
    $nodeVer = (node --version).TrimStart('v')
    Write-Host "[INFO] Node.js upgraded to version: $nodeVer"
} else {
    Write-Host "[INFO] Node.js version meets requirement (≥ $requiredNode)."
}

# Step 3: Update npm
Write-Host "[INFO] Updating npm to latest version..."
try {
    npm install -g npm | Out-Host
    $npmVer = npm --version
    Write-Host "[INFO] npm updated to version: $npmVer"
} catch {
    Write-Error "[ERROR] Failed to update npm. $_"
    exit 1
}

# Step 4: Install Google Gemini CLI
Write-Host "[INFO] Installing Google Gemini CLI globally..."
try {
    npm install -g @google/gemini-cli | Out-Host
} catch {
    Write-Error "[ERROR] Gemini CLI installation failed. $_"
    exit 1
}

# Step 5: Verify Gemini CLI
Write-Host "[INFO] Verifying Gemini CLI installation..."
try {
    $gemVer = gemini --version
    Write-Host "[SUCCESS] Google Gemini CLI installed. Version: $gemVer"
} catch {
    Write-Error "[ERROR] Gemini CLI not found in PATH. Ensure npm global bin is in your PATH."
    exit 1
}

Write-Host "[INFO] Installation complete. You can now run 'gemini' in this shell."
