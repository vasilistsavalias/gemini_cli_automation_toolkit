# -------------------------------
# PowerShell script to bootstrap a Gemini ML project
# v2.0 - Fixed for PowerShell 5.1 compatibility and enhanced privacy
# -------------------------------
$ErrorActionPreference = "Stop"

# Configuration (modify these as needed)
$venvName = ".venv"
$additionalPackages = @()  # Add extra packages here if needed
$geminiModel = "gemini-2.5-pro"
$outputFormat = "markdown"
# Set to $true to have the script ask for your API key during setup.
# By default ($false), it creates a safe .env.template file.
$promptForApiKey = $false

$projectName = Split-Path -Leaf (Get-Location)
Write-Host "`nSetting up new Gemini ML project: $projectName" -ForegroundColor Cyan

# Step 1: Create virtual environment
if (-Not (Test-Path $venvName)) {
    Write-Host "Creating virtual environment $venvName ..."
    python -m venv $venvName
}
else {
    Write-Host "Virtual environment $venvName already exists. Skipping."
}

# Determine Python executable path
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $venvPython = Join-Path $venvName "Scripts\python.exe"
}
else {
    $venvPython = Join-Path $venvName "bin/python"
}

if (-Not (Test-Path $venvPython)) {
    Write-Error "Virtual environment Python executable not found at $venvPython"
}

# Step 2: Upgrade pip
Write-Host "Upgrading pip ..."
& $venvPython -m pip install --upgrade pip

# Step 3: Install packages
# NOTE: pyyaml is added so we can generate YAML requirements reliably
$defaultPackages = @(
    "google-generativeai",
    "ipython",
    "pyyaml"
)
$packagesToInstall = $defaultPackages + $additionalPackages
Write-Host "Installing packages ..."
foreach ($pkg in $packagesToInstall) {
    Write-Host "Installing: $pkg"
    & $venvPython -m pip install $pkg
}

# Step 4: Create requirements.yaml (PowerShell 5.1 Compatible Fix)
Write-Host "Writing requirements.json (intermediate) ..."
$reqJson = "requirements.json"
$reqYaml = "requirements.yaml"

# FIX: Use a method compatible with older PowerShell to write UTF8 without a BOM
$reqJsonContent = & $venvPython -m pip list --format=json
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($reqJson, $reqJsonContent, $utf8WithoutBom)

Write-Host "Converting $reqJson -> $reqYaml ..."
$pyTemp = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ([System.IO.Path]::GetRandomFileName() + ".py"))
@"
import json, sys
try:
    import yaml
except Exception:
    sys.exit('PyYAML missing in venv; please install pyyaml and re-run the script.')
# Read with standard 'utf-8' which now matches the BOM-less file
with open(r'$reqJson', 'r', encoding='utf-8') as f:
    data = json.load(f)
out = {pkg['name']: pkg['version'] for pkg in data if 'name' in pkg and 'version' in pkg}
with open(r'$reqYaml', 'w', encoding='utf-8') as f:
    yaml.safe_dump(out, f, sort_keys=False)
"@ | Out-File -Encoding UTF8 $pyTemp

& $venvPython $pyTemp
Remove-Item $pyTemp -Force

# Force-remove the intermediate JSON file so repo stays clean
Remove-Item $reqJson -ErrorAction SilentlyContinue

if (Test-Path $reqYaml) {
    Write-Host "Requirements written to $reqYaml"
}
else {
    Write-Error "Failed to write $reqYaml"
}

# Step 5: Create .gitignore
$gitignoreContent = @'
# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST
*.manifest
*.spec
pip-log.txt
pip-delete-this-directory.txt
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/
htmlcov/
report.xml
junit/
*.mo
*.pot
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal
instance/
.webassets-cache
.scrapy
docs/_build/
target/
.ipynb_checkpoints
.profile
.python-version

# Local environment and secrets
.venv/
.env

# IDE and OS files
.vscode/
.idea/
.DS_Store
'@

if (-Not (Test-Path ".gitignore")) {
    Write-Host "Creating .gitignore ..."
    $gitignoreContent | Out-File -Encoding UTF8 .gitignore
}

# Step 6: Create .env handling (Guaranteed Privacy Fix)
$envFile = ".env"

# Ensure .env exists (empty if not)
if (-not (Test-Path $envFile)) {
    New-Item -ItemType File -Path $envFile | Out-Null
    Write-Host "Created new .env file."
}

if ($promptForApiKey) {
    # Securely prompt for GEMINI_API_KEY
    Write-Host "Prompting for GEMINI_API_KEY (input will be hidden)."
    $secure = Read-Host "Enter GEMINI_API_KEY (input hidden)" -AsSecureString
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }

    # Overwrite or update GEMINI_API_KEY safely
    $existing = if (Test-Path $envFile) { Get-Content $envFile } else { @() }
    $filtered = $existing | Where-Object { $_ -notmatch '^GEMINI_API_KEY=' }
    $filtered + "GEMINI_API_KEY=$apiKey" | Out-File -Encoding UTF8 $envFile

    Write-Host ".env updated with GEMINI_API_KEY. Do NOT commit this file."
}
else {
    # Ensure .env at least contains a placeholder if empty
    if ((Get-Content $envFile -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        "GEMINI_API_KEY=your_api_key_here" | Out-File -Encoding UTF8 $envFile
        Write-Host "Wrote placeholder GEMINI_API_KEY to .env (safe default)."
    }
    else {
        Write-Host ".env already exists. No changes made."
    }
}


# Step 7: Create a focused README.md and Gemini.md
$geminiFile = "Gemini.md"
if (-Not (Test-Path $geminiFile)) {
    Write-Host "Creating Gemini.md in project root..."
    @"
# Gemini CLI Notes

This file is intended for notes, commands, and logs related to using the Gemini API in this project.

* Record prompts, outputs, or debugging info here.
* Use this as a project-specific reference for Gemini interactions.
"@ | Out-File -Encoding UTF8 $geminiFile
}

$readmeContent = @"
# $($projectName) Project Structure

This file provides a brief analysis of the core files and directories created by the setup script.

*   `./.venv/`
    *   **Purpose**: Virtual environment, sandboxed Python interpreter and packages.

*   `./.env.template`
    *   **Purpose**: A template for your secrets file. Rename this to `.env` and add your `GEMINI_API_KEY`.

*   `./.gitignore`
    *   **Purpose**: Tells Git which files/directories to ignore (e.g., `.venv`, `.env`).

*   `./requirements.yaml`
    *   **Purpose**: Lists Python packages & versions for reproducible installs.

*   `./LICENSE.md`
    *   **Purpose**: Contains GNU GPL v3 license text.

*   `./memory/`
    *   **Purpose**: Local folder for short-lived project memory files.

*   `./opinions/`
    *   **Purpose**: Folder for AI-generated or curated opinion markdown files (e.g., claude.md, chatgpt.md, gemini.md).

*   `./Gemini.md`
    *   **Purpose**: Root-level markdown file for project-specific Gemini notes, experiments, or logs.
"@

if (-Not (Test-Path "README.md")) {
    Write-Host "Creating README.md..."
    $readmeContent | Out-File -Encoding UTF8 README.md
}
else {
    Write-Host "README.md exists, not overwriting."
}

# Step 8: Create LICENSE.md (GNU GPL v3 - Privacy Fix)
$licenseFile = "LICENSE.md"
if (-Not (Test-Path $licenseFile)) {
    Write-Host "Fetching GNU GPL v3 text into $licenseFile ..."
    $gplUrl = "https://www.gnu.org/licenses/gpl-3.0.txt"
    $tmpLicense = "LICENSE.tmp"
    try {
        Invoke-WebRequest -Uri $gplUrl -OutFile $tmpLicense -UseBasicParsing -ErrorAction Stop
        $year = (Get-Date).Year
        # FIX: Use a generic, impersonal header. Does not look up username.
        $header = "Copyright (c) $year`r`nSPDX-License-Identifier: GPL-3.0-or-later`r`n`r`n"
        $licenseText = Get-Content -Raw -Encoding UTF8 $tmpLicense
        ($header + $licenseText) | Out-File -Encoding UTF8 $licenseFile
        Remove-Item $tmpLicense -Force
        Write-Host "LICENSE.md written (GPLv3)."
    }
    catch {
        Write-Warning "Unable to fetch GNU GPL text. Writing minimal SPDX header to $licenseFile"
        $spdx = "SPDX-License-Identifier: GPL-3.0-or-later"
        $year = (Get-Date).Year
        # FIX: Use a generic, impersonal header.
        $header = "Copyright (c) $year`r`n$spdx"
        $header | Out-File -Encoding UTF8 $licenseFile
    }
}
else {
    Write-Host "LICENSE.md exists, not overwriting."
}

# Step 9: Create memory folder
if (-Not (Test-Path "memory")) {
    Write-Host "Creating memory/ folder ..."
    New-Item -ItemType Directory -Path "memory" | Out-Null
}
else {
    Write-Host "memory/ folder already exists. Skipping."
}

# Step 10: Create opinions folder with AI markdown files
if (-Not (Test-Path "opinions")) {
    Write-Host "Creating opinions/ folder ..."
    New-Item -ItemType Directory -Path "opinions" | Out-Null

    Write-Host "Creating AI opinion files ..."
    @("claude.md", "chatgpt.md", "gemini.md") | ForEach-Object {
        $opinionFile = Join-Path "opinions" $_
        "" | Out-File -Encoding UTF8 $opinionFile
        Write-Host "  Created: $opinionFile"
    }
}
else {
    Write-Host "opinions/ folder already exists. Skipping."
}

Write-Host "`nProject setup complete!" -ForegroundColor Green