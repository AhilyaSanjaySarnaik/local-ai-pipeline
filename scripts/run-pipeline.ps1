param(
    [string]$Prompt = "Generate a short operational status report for the local AI pipeline.",
    [string]$Model = "qwen3:4b"
)

$ErrorActionPreference = "Stop"

$Root = "D:\local-ai-pipeline"
$VenvPython = "$Root\templates\python\venv\Scripts\python.exe"
$ClientScript = "$Root\services\ai-api\client.py"
$ProjectsDir = "$Root\projects"
$OutputFile = "$ProjectsDir\pipeline_output.md"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       LOCAL AI PIPELINE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$PipelineFailed = $false

# --------------------------------------------------
# 1. Check Ollama
# --------------------------------------------------

Write-Host "[1/7] Checking Ollama..." -NoNewline

try {
    $OllamaResponse = Invoke-RestMethod `
        -Uri "http://localhost:11434/api/tags" `
        -Method Get `
        -TimeoutSec 10

    Write-Host " OK" -ForegroundColor Green
}
catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "      Ollama is not reachable at http://localhost:11434" -ForegroundColor Red
    $PipelineFailed = $true
}

# --------------------------------------------------
# 2. Check required model
# --------------------------------------------------

Write-Host "[2/7] Checking model $Model..." -NoNewline

if (-not $PipelineFailed) {
    $ModelExists = $OllamaResponse.models |
        Where-Object { $_.name -eq $Model }

    if ($ModelExists) {
        Write-Host " OK" -ForegroundColor Green
    }
    else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "      Model '$Model' is not installed." -ForegroundColor Red
        Write-Host "      Available models:" -ForegroundColor Yellow

        foreach ($AvailableModel in $OllamaResponse.models) {
            Write-Host "        - $($AvailableModel.name)"
        }

        $PipelineFailed = $true
    }
}
else {
    Write-Host " SKIPPED" -ForegroundColor Yellow
}

# --------------------------------------------------
# 3. Check Docker
# --------------------------------------------------

Write-Host "[3/7] Checking Docker..." -NoNewline

try {
    $DockerInfo = docker info 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    }
    else {
        throw "Docker is not running"
    }
}
catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "      Docker Desktop is not running or unavailable." -ForegroundColor Red
    $PipelineFailed = $true
}

# --------------------------------------------------
# 4. Check Python environment
# --------------------------------------------------

Write-Host "[4/7] Checking Python environment..." -NoNewline

if (Test-Path $VenvPython) {
    try {
        $PythonVersion = & $VenvPython --version 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host " OK" -ForegroundColor Green
            Write-Host "      $PythonVersion" -ForegroundColor DarkGray
        }
        else {
            throw "Python environment failed"
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $PipelineFailed = $true
    }
}
else {
    Write-Host " MISSING" -ForegroundColor Yellow
    Write-Host "      Creating Python virtual environment..." -ForegroundColor Yellow

    try {
        python -m venv "$Root\templates\python\venv"

        if (-not (Test-Path $VenvPython)) {
            throw "Virtual environment creation failed"
        }

        & $VenvPython -m pip install --quiet ollama

        Write-Host "      Python environment created." -ForegroundColor Green
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "      $($_.Exception.Message)" -ForegroundColor Red
        $PipelineFailed = $true
    }
}

# --------------------------------------------------
# 5. Run AI task
# --------------------------------------------------

Write-Host "[5/7] Running AI generation..." -NoNewline

if (-not $PipelineFailed) {

    if (-not (Test-Path $ClientScript)) {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "      client.py not found." -ForegroundColor Red
        $PipelineFailed = $true
    }
    else {
        try {
            $StartTime = Get-Date

            $AIOutput = & $VenvPython $ClientScript $Prompt 2>&1

            $EndTime = Get-Date
            $Elapsed = ($EndTime - $StartTime).TotalSeconds

            if ($LASTEXITCODE -ne 0) {
                throw "AI client exited with code $LASTEXITCODE"
            }

            if ([string]::IsNullOrWhiteSpace(($AIOutput -join ""))) {
                throw "AI returned empty output"
            }

            if (($AIOutput -join "`n") -match "Error connecting to local AI pipeline") {
                throw ($AIOutput -join "`n")
            }

            Write-Host " OK" -ForegroundColor Green
            Write-Host "      Generation time: $([math]::Round($Elapsed, 1)) seconds" -ForegroundColor DarkGray
        }
        catch {
            Write-Host " FAILED" -ForegroundColor Red
            Write-Host "      $($_.Exception.Message)" -ForegroundColor Red
            $PipelineFailed = $true
        }
    }
}
else {
    Write-Host " SKIPPED" -ForegroundColor Yellow
}

# --------------------------------------------------
# 6. Validate and save output
# --------------------------------------------------

Write-Host "[6/7] Validating output..." -NoNewline

if (-not $PipelineFailed) {
    try {
        $OutputText = $AIOutput -join "`n"

        if ($OutputText.Length -lt 10) {
            throw "Generated output is too short"
        }

        if (-not (Test-Path $ProjectsDir)) {
            New-Item -ItemType Directory -Path $ProjectsDir -Force | Out-Null
        }

        $OutputText | Out-File `
            -FilePath $OutputFile `
            -Encoding UTF8

        Write-Host " OK" -ForegroundColor Green
        Write-Host "      Output saved to: $OutputFile" -ForegroundColor DarkGray
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "      $($_.Exception.Message)" -ForegroundColor Red
        $PipelineFailed = $true
    }
}
else {
    Write-Host " SKIPPED" -ForegroundColor Yellow
}

# --------------------------------------------------
# 7. Final pipeline status
# --------------------------------------------------

Write-Host "[7/7] Pipeline status..." -NoNewline

if ($PipelineFailed) {
    Write-Host " FAILED" -ForegroundColor Red

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "       PIPELINE FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""

    exit 1
}
else {
    Write-Host " SUCCESS" -ForegroundColor Green

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "       PIPELINE SUCCESS" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Model:       $Model"
    Write-Host "Output:      $OutputFile"
    Write-Host ""
}
