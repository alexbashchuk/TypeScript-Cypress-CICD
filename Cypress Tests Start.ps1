param(
    [string[]]$Specs = @(
        "cypress/e2e/portfolio-home.cy.ts"
    ),

    [ValidateSet("chrome", "edge", "firefox", "electron")]
    [string]$Browser = "chrome",

    [ValidateSet("headed", "headless")]
    [string]$Mode = "headed"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$timestamp = Get-Date -Format "MM-dd-yyyy--HH-mm-ss"
$logFile = Join-Path $projectRoot "Cypress-$timestamp.txt"

Start-Transcript -Path $logFile -Force | Out-Null

try {
    Write-Host "Log file: $logFile"
    Write-Host "Current folder: $projectRoot"
    Write-Host "Browser: $Browser"
    Write-Host "Mode: $Mode"
    Write-Host "Specs to run:"
    $Specs | ForEach-Object { Write-Host " - $_" }

    if (-not (Test-Path (Join-Path $projectRoot "package.json"))) {
        throw "package.json was not found in $projectRoot"
    }

    $npxCmd = Get-Command npx.cmd -ErrorAction SilentlyContinue
    if (-not $npxCmd) {
        $npxCmd = Get-Command npx -ErrorAction SilentlyContinue
    }

    if (-not $npxCmd) {
        throw "npx was not found. Make sure Node.js is installed and available in PATH."
    }

    $specArgument = ($Specs -join ",")
    Write-Host "Spec argument: $specArgument"

    $cypressArgs = @(
        "cypress",
        "run",
        "--browser", $Browser,
        "--spec", $specArgument
    )

    if ($Mode -eq "headed") {
        $cypressArgs += "--headed"
    }

    Write-Host ""
    Write-Host "Running command:"
    Write-Host "$($npxCmd.Source) $($cypressArgs -join ' ')"
    Write-Host ""

    & $npxCmd.Source @cypressArgs
    $cypressExitCode = $LASTEXITCODE

    Write-Host ""
    Write-Host "Cypress exit code: $cypressExitCode"

    if ($cypressExitCode -ne 0) {
        throw "Cypress finished with exit code $cypressExitCode"
    }

    Write-Host "Cypress finished successfully."
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
finally {
    try {
        Stop-Transcript | Out-Null
    }
    catch {
        Write-Host "Transcript close warning: $($_.Exception.Message)"
    }
}