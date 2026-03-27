param(
    [string[]]$Specs = @(
        "cypress/e2e/portfolio-home.cy.ts",
        "cypress/e2e/portfolio-certifications.cy.ts"
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
$allureResultsDir = Join-Path $projectRoot "allure-results"
$allureReportsRoot = Join-Path $projectRoot "allure-reports"
$allureReportDir = Join-Path $allureReportsRoot "allure-report-$timestamp"
$allureLatestReportDir = Join-Path $allureReportsRoot "allure-report-latest"
$allureHistoryTempDir = Join-Path $projectRoot ".allure-history-temp"

function Read-YesNo {
    param(
        [string]$Prompt,
        [bool]$Default = $false
    )

    while ($true) {
        if ($Default) {
            $reply = Read-Host "$Prompt [Y/n]"
            if ([string]::IsNullOrWhiteSpace($reply)) {
                return $true
            }
        }
        else {
            $reply = Read-Host "$Prompt [y/N]"
            if ([string]::IsNullOrWhiteSpace($reply)) {
                return $false
            }
        }

        switch ($reply.Trim().ToLower()) {
            'y'   { return $true }
            'yes' { return $true }
            'n'   { return $false }
            'no'  { return $false }
            default {
                Write-Host "Please enter Yes or No."
            }
        }
    }
}

function Read-Choice {
    param(
        [string]$Prompt,
        [string[]]$Choices,
        [string]$Default
    )

    if (-not $Choices -or $Choices.Count -eq 0) {
        throw "Read-Choice requires at least one choice."
    }

    while ($true) {
        Write-Host ""
        Write-Host $Prompt

        for ($i = 0; $i -lt $Choices.Count; $i++) {
            $marker = if ($Choices[$i] -eq $Default) { " (default)" } else { "" }
            Write-Host ("{0}) {1}{2}" -f ($i + 1), $Choices[$i], $marker)
        }

        $reply = Read-Host "Enter number or name"

        if ([string]::IsNullOrWhiteSpace($reply)) {
            return $Default
        }

        $trimmedReply = $reply.Trim()
        $numericChoice = 0

        if ([int]::TryParse($trimmedReply, [ref]$numericChoice)) {
            if ($numericChoice -ge 1 -and $numericChoice -le $Choices.Count) {
                return $Choices[$numericChoice - 1]
            }
        }

        foreach ($choice in $Choices) {
            if ($choice.Equals($trimmedReply, [System.StringComparison]::OrdinalIgnoreCase)) {
                return $choice
            }
        }

        Write-Host "Invalid selection. Please choose one of: $($Choices -join ', ')"
    }
}

function Get-LatestAllureHistorySource {
    param(
        [string]$ReportsRoot,
        [string]$LatestReportDir
    )

    $latestHistoryDir = Join-Path $LatestReportDir "history"
    if (Test-Path $latestHistoryDir) {
        return $latestHistoryDir
    }

    if (-not (Test-Path $ReportsRoot)) {
        return $null
    }

    $previousReport = Get-ChildItem -Path $ReportsRoot -Directory |
        Where-Object {
            $_.Name -like "allure-report-*" -and
            $_.Name -ne "allure-report-latest" -and
            (Test-Path (Join-Path $_.FullName "history"))
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($previousReport) {
        return (Join-Path $previousReport.FullName "history")
    }

    return $null
}

Start-Transcript -Path $logFile -Force | Out-Null

try {
    $Browser = Read-Choice -Prompt "Select browser for Cypress run:" -Choices @("chrome", "edge", "firefox", "electron") -Default $Browser
    $Mode = Read-Choice -Prompt "Select browser mode:" -Choices @("headed", "headless") -Default $Mode
    $generateAllureReport = Read-YesNo -Prompt "Generate Allure report after test run?" -Default $false

    Write-Host ""
    Write-Host "Log file: $logFile"
    Write-Host "Current folder: $projectRoot"
    Write-Host "Browser: $Browser"
    Write-Host "Mode: $Mode"
    Write-Host "Generate Allure Report: $generateAllureReport"
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

    if ($generateAllureReport) {
        Write-Host ""
        Write-Host "Preparing Allure history and cleaning previous raw results..."

        if (Test-Path $allureHistoryTempDir) {
            Remove-Item -Path $allureHistoryTempDir -Recurse -Force
        }

        $previousHistorySource = Get-LatestAllureHistorySource -ReportsRoot $allureReportsRoot -LatestReportDir $allureLatestReportDir

        if ($previousHistorySource) {
            Copy-Item -Path $previousHistorySource -Destination $allureHistoryTempDir -Recurse -Force
            Write-Host "Previous Allure history found and backed up from: $previousHistorySource"
        }
        else {
            Write-Host "No previous Allure history found. A fresh trend history will start with this run."
        }

        if (Test-Path $allureResultsDir) {
            Remove-Item -Path $allureResultsDir -Recurse -Force
            Write-Host "Deleted previous raw Allure results: $allureResultsDir"
        }
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
    Write-Host "Running Cypress command:"
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

    if ($generateAllureReport) {
        Write-Host ""
        Write-Host "Preparing Allure report..."

        if (-not (Test-Path $allureResultsDir)) {
            throw "Allure results folder was not found: $allureResultsDir"
        }

        if (-not (Test-Path $allureReportsRoot)) {
            New-Item -ItemType Directory -Path $allureReportsRoot | Out-Null
        }

        if (Test-Path $allureHistoryTempDir) {
            $historyDestinationDir = Join-Path $allureResultsDir "history"

            if (Test-Path $historyDestinationDir) {
                Remove-Item -Path $historyDestinationDir -Recurse -Force
            }

            Copy-Item -Path $allureHistoryTempDir -Destination $historyDestinationDir -Recurse -Force
            Write-Host "Restored previous Allure history into: $historyDestinationDir"
        }

        $allureCmd = Get-Command allure.bat -ErrorAction SilentlyContinue
        if (-not $allureCmd) {
            $allureCmd = Get-Command allure.cmd -ErrorAction SilentlyContinue
        }
        if (-not $allureCmd) {
            $allureCmd = Get-Command allure -ErrorAction SilentlyContinue
        }

        if (-not $allureCmd) {
            throw "Allure CLI was not found in PATH."
        }

        $allureArgs = @(
            "generate",
            $allureResultsDir,
            "--clean",
            "-o",
            $allureReportDir
        )

        Write-Host "Running Allure command:"
        Write-Host "$($allureCmd.Source) $($allureArgs -join ' ')"
        Write-Host ""

        & $allureCmd.Source @allureArgs
        $allureExitCode = $LASTEXITCODE

        Write-Host ""
        Write-Host "Allure exit code: $allureExitCode"

        if ($allureExitCode -ne 0) {
            throw "Allure report generation finished with exit code $allureExitCode"
        }

        if (Test-Path $allureLatestReportDir) {
            Remove-Item -Path $allureLatestReportDir -Recurse -Force
        }

        Copy-Item -Path $allureReportDir -Destination $allureLatestReportDir -Recurse -Force

        Write-Host "Allure report created successfully."
        Write-Host "Timestamped report: $allureReportDir"
        Write-Host "Latest report copy: $allureLatestReportDir"
    }
    else {
        Write-Host "Allure report generation skipped."
    }
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Test-Path $allureHistoryTempDir) {
        try {
            Remove-Item -Path $allureHistoryTempDir -Recurse -Force
        }
        catch {
            Write-Host "Temporary Allure history cleanup warning: $($_.Exception.Message)"
        }
    }

    try {
        Stop-Transcript | Out-Null
    }
    catch {
        Write-Host "Transcript close warning: $($_.Exception.Message)"
    }
}
